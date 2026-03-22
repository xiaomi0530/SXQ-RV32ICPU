import sys, hashlib

def md5_file(path):
    h = hashlib.md5()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
    return h.hexdigest()

def md5_bytes(data):
    return hashlib.md5(data).hexdigest()

args = sys.argv[1:]
if args and args != ['-']:
    for path in args:
        if path == '-':
            data = sys.stdin.buffer.read()
            print(f"{md5_bytes(data)}  -")
        else:
            print(f"{md5_file(path)}  {path}")
else:
    data = sys.stdin.buffer.read()
    print(f"{md5_bytes(data)}  -")
