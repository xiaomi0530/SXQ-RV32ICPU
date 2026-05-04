# Benchmark Summary

Clock frequency: `100 MHz`  
Toolchain: `riscv64-unknown-elf-gcc`

## Build Parameters

| Benchmark | Build Flags / Config |
| --- | --- |
| CoreMark | `-march=rv32im -mabi=ilp32 -mstrict-align -O2` ; `ITERATIONS=5000` |
| Dhrystone | `-march=rv32im -mabi=ilp32 -mstrict-align -O2 -std=gnu89` ; `DHRY_HZ=100000000` ; `1800 runs` |
| Embench-WikiSort | `-march=rv32im -mabi=ilp32 -mstrict-align -O2 -std=gnu11` ; `BENCH=wikisort` ; `GLOBAL_SCALE_FACTOR=1` ; `WARMUP_HEAT=1` |

**CoreMark**

2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 1812106815
Total time (secs): 18.121068
Iterations/Sec   : 275.921925
Iterations       : 5000
Compiler version : riscv64-unknown-elf-gcc
Compiler flags   : -march=rv32im -mabi=ilp32 -mstrict-align -O2
Memory location  : STATIC
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0xbd59
Correct operation validated. See README.md for run and reporting rules.
CoreMark 1.0 : 275.921925 / riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -mstrict-align -O2 / STATIC
[TBIPC] BENCH C=362458  I=308288  IPC=0.851  done=1
[TBPRED] B    N=62294  dir=87.06%  tgt=100.00%  total=87.06%
[TBPRED] JAL  N=5230  dir=100.00%  tgt=100.00%  total=100.00%
[TBPRED] JALR N=2136  dir=100.00%  tgt=99.91%  total=99.91%
[TBPRED] ALL  N=69660  dir=88.43%  tgt=99.99%  total=88.43%  miss=11.57%

**Dhrystone**
Dhrystone Benchmark, Version C, Version 2.2
Program compiled without 'register' attribute
Using mmio_cycle, HZ=100000000

Trying 1800 runs through Dhrystone:
Final values of the variables used in the benchmark:

Int_Glob:            5
        should be:   5
Bool_Glob:           1
        should be:   1
Ch_1_Glob:           A
        should be:   A
Ch_2_Glob:           B
        should be:   B
Arr_1_Glob[8]:       7
        should be:   7
Arr_2_Glob[8][7]:    1810
        should be:   Number_Of_Runs + 10
Ptr_Glob->
  Ptr_Comp:          98048
        should be:   (implementation-dependent)
  Discr:             0
        should be:   0
  Enum_Comp:         2
        should be:   2
  Int_Comp:          17
        should be:   17
  Str_Comp:          DHRYSTONE PROGRAM, SOME STRING
        should be:   DHRYSTONE PROGRAM, SOME STRING
Next_Ptr_Glob->
  Ptr_Comp:          98048
        should be:   (implementation-dependent), same as above
  Discr:             0
        should be:   0
  Enum_Comp:         1
        should be:   1
  Int_Comp:          18
        should be:   18
  Str_Comp:          DHRYSTONE PROGRAM, SOME STRING
        should be:   DHRYSTONE PROGRAM, SOME STRING
Int_1_Loc:           5
        should be:   5
Int_2_Loc:           13
        should be:   13
Int_3_Loc:           7
        should be:   7
Enum_Loc:            1
        should be:   1
Str_1_Loc:           DHRYSTONE PROGRAM, 1'ST STRING
        should be:   DHRYSTONE PROGRAM, 1'ST STRING
Str_2_Loc:           DHRYSTONE PROGRAM, 2'ND STRING
        should be:   DHRYSTONE PROGRAM, 2'ND STRING

Microseconds for one run through Dhrystone: 6
Dhrystones per Second:                      166000
[TBIPC] BENCH C=1081810  I=980993  IPC=0.907  done=1

**Embench-wikisort**
WS V=1 S=122.58
[TBIPC] BENCH C=2965138  I=2330989  IPC=0.786  done=1
