#!/bin/bash
# テスト実行。SCRIPT ERROR が1つでも出たら失敗扱いにする。
cd "$(dirname "$0")"
godot --headless --path . --import >/dev/null 2>&1
out=$(godot --headless --path . -s addons/minitest/run.gd -- "$@" 2>&1)
code=$?
echo "$out" | grep -E "^FAIL|tests,|SCRIPT ERROR|Parse Error" | head -40
if echo "$out" | grep -q "SCRIPT ERROR"; then echo "SCRIPT ERRORS FOUND"; exit 1; fi
exit $code
