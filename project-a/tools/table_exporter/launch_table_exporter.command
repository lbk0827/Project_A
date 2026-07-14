#!/bin/zsh

SCRIPT_DIR="${0:a:h}"
CODEX_PYTHON="/Users/bk/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"

cd "$SCRIPT_DIR" || exit 1

if [[ -x "$CODEX_PYTHON" ]]; then
  "$CODEX_PYTHON" table_exporter_gui.py
else
  python3 table_exporter_gui.py
fi
