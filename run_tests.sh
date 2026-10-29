#!/bin/sh
# Lance les tests en mode headless (Linux, macOS ou Git Bash), puis lance le
# jeu 300 images (le niveau 1), puis l'enfance, l'été, la pluie, la maison et
# l'Égypte
# 300 images chacune. Échoue si un test échoue ou si une erreur de script apparaît.
GODOT="${GODOT:-godot}"
DIR="$(dirname "$0")"
LOG="$(mktemp)"
"$GODOT" --headless --path "$DIR" --import >/dev/null 2>&1
"$GODOT" --headless --path "$DIR" -s res://tests/run_tests.gd >"$LOG" 2>&1
CODE=$?
"$GODOT" --headless --path "$DIR" --quit-after 300 >>"$LOG" 2>&1
"$GODOT" --headless --path "$DIR" --quit-after 300 res://scenes/enfance.tscn >>"$LOG" 2>&1
"$GODOT" --headless --path "$DIR" --quit-after 300 res://scenes/ete.tscn >>"$LOG" 2>&1
"$GODOT" --headless --path "$DIR" --quit-after 300 res://scenes/dispute.tscn >>"$LOG" 2>&1
"$GODOT" --headless --path "$DIR" --quit-after 300 res://scenes/maison.tscn >>"$LOG" 2>&1
"$GODOT" --headless --path "$DIR" --quit-after 300 res://scenes/egypte.tscn >>"$LOG" 2>&1
grep -vE "^\s+(at:|\[[0-9]+\]|GDScript backtrace)" "$LOG"
if grep -qE "SCRIPT ERROR|^ERROR" "$LOG"; then
	echo "Des erreurs sont apparues dans le journal."
	CODE=1
fi
rm -f "$LOG"
exit $CODE
