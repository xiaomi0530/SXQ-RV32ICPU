$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptDir '..\..'))
$simDir = Join-Path $repoRoot 'sim_1\new'
$resultsDir = Join-Path $scriptDir 'results'
$baselinePath = Join-Path $scriptDir 'baseline-data\speed.json'
$cpuFreqHz = 100000000.0
$cpuFreqMHz = 100.0
$globalScaleFactor = 1.0
$benchmarks = @('crc32', 'matmult-int', 'edn', 'slre', 'wikisort')

New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null

function Invoke-NativeChecked {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        & $FilePath @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed: $FilePath $($Arguments -join ' ')"
        }
    }
    finally {
        Pop-Location
    }
}

function Ensure-SimBinary {
    $simBinary = Join-Path $simDir 'cpu_tb_ivl.out'
    if (Test-Path $simBinary) {
        return $simBinary
    }

    $files = Get-ChildItem (Join-Path $repoRoot 'sources_1\new'), $simDir -Recurse -Include *.v,*.sv |
        Sort-Object FullName |
        ForEach-Object { $_.FullName }

    Push-Location $simDir
    try {
        & iverilog -g2012 -I ..\..\sources_1\new -o cpu_tb_ivl.out -s cpu_tb @files
        if ($LASTEXITCODE -ne 0) {
            throw 'iverilog compile failed'
        }
    }
    finally {
        Pop-Location
    }

    return $simBinary
}

function Parse-BenchmarkLog {
    param(
        [string]$Bench,
        [string]$LogPath,
        [object]$Baseline
    )

    $text = Get-Content $LogPath -Raw

    $ipcMatch = [regex]::Match($text, '\[TBIPC\]\s+C=(\d+)\s+I=(\d+)\s+IPC=([0-9]+\.[0-9]+)')
    if (-not $ipcMatch.Success) {
        throw "Missing IPC in $Bench log"
    }

    $cycles = [double]$ipcMatch.Groups[1].Value
    $instret = [double]$ipcMatch.Groups[2].Value
    $statCycles = $cycles
    $ipc = [double]$ipcMatch.Groups[3].Value
    $cpi = if ($instret -ne 0.0) { [double]($cycles / $instret) } else { 0.0 }

    $verifyMatch = [regex]::Match($text, 'WS\s+V=(\d+)')
    $verify = if ($verifyMatch.Success) { [int]$verifyMatch.Groups[1].Value } else { -1 }

    $rawMs = $cycles * 1000.0 / $cpuFreqHz
    $baselineMs = [double]$Baseline.$Bench
    $speedScore = $baselineMs / $rawMs * $globalScaleFactor

    [PSCustomObject]@{
        benchmark       = $Bench
        cycles          = [int64][math]::Round($cycles)
        stat_cycles     = [int64][math]::Round($statCycles)
        ipc             = [math]::Round($ipc, 3)
        cpi             = [math]::Round($cpi, 3)
        runtime_ms      = [math]::Round($rawMs, 3)
        baseline_ms     = [math]::Round($baselineMs, 3)
        embench_score   = [math]::Round($speedScore, 3)
        verify_ok       = ($verify -eq 1)
        log             = $LogPath
    }
}

$baseline = Get-Content $baselinePath -Raw | ConvertFrom-Json
$simBinary = Ensure-SimBinary
$summary = @()

foreach ($bench in $benchmarks) {
    Write-Output "=== BUILD $bench ==="
    Invoke-NativeChecked -FilePath 'make' -Arguments @("BENCH=$bench", 'install', 'INSTALL_IMEM=../../sim_1/new/imem.mem') -WorkingDirectory $scriptDir

    Write-Output "=== RUN $bench ==="
    $logPath = Join-Path $resultsDir "$bench.log"

    Push-Location $simDir
    try {
        & vvp $simBinary 2>&1 | Tee-Object -FilePath $logPath
        if ($LASTEXITCODE -ne 0) {
            throw "Simulation failed for $bench"
        }
    }
    finally {
        Pop-Location
    }

    $summary += Parse-BenchmarkLog -Bench $bench -LogPath $logPath -Baseline $baseline
}

$jsonPath = Join-Path $resultsDir 'top5_summary.json'
$mdPath = Join-Path $resultsDir 'top5_summary.md'

$summary | ConvertTo-Json -Depth 4 | Set-Content $jsonPath

$md = @()
$md += '| Benchmark | Embench Score | IPC | CPI | Cycles | Runtime (ms) | Verify |'
$md += '|---|---:|---:|---:|---:|---:|---|'
foreach ($row in $summary) {
    $md += "| $($row.benchmark) | $($row.embench_score) | $($row.ipc) | $($row.cpi) | $($row.cycles) | $($row.runtime_ms) | $($row.verify_ok) |"
}
$md -join [Environment]::NewLine | Set-Content $mdPath

Write-Output ''
Write-Output '=== SUMMARY ==='
$summary | Format-Table benchmark, embench_score, ipc, cpi, cycles, runtime_ms, verify_ok -AutoSize
Write-Output "JSON: $jsonPath"
Write-Output "MD  : $mdPath"
