import re, sys
args = sys.argv[1:]
if not args or not args[0].startswith('-c'):
    sys.exit(1)
range_part = args[0][2:]
match = re.fullmatch(r'(\d+)-(\d+)', range_part)
if not match:
    sys.exit(1)
start = int(match.group(1))
end = int(match.group(2))
if start < 1 or end < start:
    sys.exit(1)
text = sys.stdin.read()
result = ''.join(ch for idx, ch in enumerate(text, start=1) if start <= idx <= end)
print(result, end='')
