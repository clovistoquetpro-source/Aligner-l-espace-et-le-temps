#!/bin/sh
# Lance les tests en mode headless (Linux, macOS ou Git Bash).
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path "$(dirname "$0")" --import >/dev/null 2>&1
exec "$GODOT" --headless --path "$(dirname "$0")" -s res://tests/run_tests.gd
