#!/usr/bin/env bash
set -euo pipefail

# Deermine shared library extension
if [ "${OS:-}" = Windows_NT ]; then
LIB_PREFIX=
SHLIB_EXT=dll
elif [ "`uname`" = Darwin ]; then
LIB_PREFIX=lib
SHLIB_EXT=dylib
else
LIB_PREFIX=lib
SHLIB_EXT=so
fi

# Reset test
./cTheoremAI.sh
lake update -q

# Build plugins
lake build
LIB_DIR=.lake/build/lib
check_plugin () {
  plugin=$1
  shlib=$LIB_DIR/${LIB_PREFIX}$plugin.$SHLIB_EXT
  test -f $shlib || {
    echo "$plugin library not found; $LIB_DIR contains:"
    ls $LIB_DIR
    exit 1
  }
}
check_plugin UserPlugin
check_plugin UserEnvPlugin
PLUGIN=$LIB_DIR/${LIB_PREFIX}UserPlugin.$SHLIB_EXT
ENV_PLUGIN=$LIB_DIR/${LIB_PREFIX}UserEnvPlugin.$SHLIB_EXT

# Expected test output
EXPECTED_OUT="Ran builtin initializer"
ENV_EXPECTED_OUT="Builtin value"

# Test plugins at elaboration-time via `theorem_ai` CLI
echo "Testing plugin load with theorem_ai CLI ..."
echo | theorem_ai --plugin=$PLUGIN --stdin 2>&1 | diff <(echo "$EXPECTED_OUT") -
lake env theorem_ai --plugin=$ENV_PLUGIN testEnvUse.theorem_ai 2>&1 | diff <(echo "$ENV_EXPECTED_OUT") -

# Test plugins at runtime via `TheoremAI.loadPlugin`
echo "Testing plugin load with TheoremAI.loadPlugin ..."
theorem_ai --run test.theorem_ai $PLUGIN 2>&1 | diff <(echo "$EXPECTED_OUT") -
lake env theorem_ai --run testEnv.theorem_ai $ENV_PLUGIN 2>&1 | diff <(echo "$ENV_EXPECTED_OUT") -

# Test failure to load environment plugin without `withImporting`
theorem_ai --run test.theorem_ai $ENV_PLUGIN >/dev/null 2>&1 && {
  echo "Loading environment plugin without importing succeeded unexpectedly."
  exit 1
} || true

# Print success
echo "Tests completed successfully."
