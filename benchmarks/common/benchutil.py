#!/usr/bin/env python3
import glob
import os
import shutil
import sys


def expand_patterns(items, keep_unmatched=True):
    expanded = []
    for item in items:
        matches = glob.glob(item)
        if matches:
            expanded.extend(matches)
        elif keep_unmatched:
            expanded.append(item)
    return expanded


def remove_paths(items):
    for path in expand_patterns(items, keep_unmatched=False):
        if os.path.isdir(path) and not os.path.islink(path):
            shutil.rmtree(path, ignore_errors=True)
        else:
            try:
                os.remove(path)
            except FileNotFoundError:
                pass


def make_dirs(items):
    for path in items:
        if path:
            os.makedirs(path, exist_ok=True)


def copy_file(src, dst):
    if os.path.isdir(dst):
        dst = os.path.join(dst, os.path.basename(src))
    parent = os.path.dirname(dst)
    if parent:
        os.makedirs(parent, exist_ok=True)
    shutil.copy2(src, dst)


def touch_files(items):
    for path in items:
        parent = os.path.dirname(path)
        if parent:
            os.makedirs(parent, exist_ok=True)
        with open(path, "a", encoding="utf-8"):
            os.utime(path, None)


def list_dirs(path):
    for name in sorted(os.listdir(path)):
        full_path = os.path.join(path, name)
        if os.path.isdir(full_path):
            print("  " + name)


def main(argv):
    if len(argv) < 2:
        raise SystemExit("usage: benchutil.py <rm|mkdir|copy|touch|list-dirs> ...")

    command = argv[1]
    args = argv[2:]

    if command == "rm":
        remove_paths(args)
    elif command == "mkdir":
        make_dirs(args)
    elif command == "copy":
        if len(args) != 2:
            raise SystemExit("copy requires <src> <dst>")
        copy_file(args[0], args[1])
    elif command == "touch":
        touch_files(args)
    elif command == "list-dirs":
        if len(args) != 1:
            raise SystemExit("list-dirs requires <path>")
        list_dirs(args[0])
    else:
        raise SystemExit("unknown command: " + command)


if __name__ == "__main__":
    main(sys.argv)
