#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NVIM_BIN="${NVIM_BIN:-nvim}"
NVIM_VERSION_LABEL="${1:-${NVIM_VERSION:-}}"

if ! command -v "$NVIM_BIN" >/dev/null 2>&1; then
  echo "Error: $NVIM_BIN not found on PATH" >&2
  exit 1
fi

echo "Running tests with ${NVIM_BIN} ${NVIM_VERSION_LABEL}" | sed 's/ $//'

DEPS_DIR="$ROOT_DIR/tests/.deps"
PLENARY_DIR="$DEPS_DIR/plenary.nvim"

if [ ! -d "$PLENARY_DIR" ]; then
  echo "Fetching plenary.nvim into $PLENARY_DIR"
  mkdir -p "$DEPS_DIR"
  git clone --depth 1 https://github.com/nvim-lua/plenary.nvim "$PLENARY_DIR"
else
  echo "Using cached plenary.nvim in $PLENARY_DIR"
fi

TEST_DIR="$ROOT_DIR/tests/spec"
if [ ! -d "$TEST_DIR" ] || [ -z "$(ls -A "$TEST_DIR")" ]; then
  echo "No tests detected under $TEST_DIR"
  exit 0
fi

"$NVIM_BIN" --headless \
  -u "$ROOT_DIR/tests/minimal_init.lua" \
  -c "PlenaryBustedDirectory tests/spec { minimal_init = 'tests/minimal_init.lua' }" \
  -c q
