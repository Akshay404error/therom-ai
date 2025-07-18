#!/usr/bin/env bash
source  ../common.sh

INIT_REQ=$'Content-Length: 46\r\n\r\n{"jsonrpc":"2.0","method":"initialize","id":1}'
INITD_NOT=$'Content-Length: 40\r\n\r\n{"jsonrpc":"2.0","method":"initialized"}'
OPEN_REQ=$'Content-Length: 145\r\n\r\n{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":"file://Test.theorem_ai","languageId":"theorem_ai4","version":0,"text":""}}}'
SD_REQ=$'Content-Length: 44\r\n\r\n{"jsonrpc":"2.0","method":"shutdown","id":2}'
EXIT_NOT=$'Content-Length: 33\r\n\r\n{"jsonrpc":"2.0","method":"exit"}'

./cTheoremAI.sh
echo "does not compile" > lakefile.theorem_ai

# ---
# Test that `lake serve` works even if `lakefile.theorem_ai` does not compile
# See https://github.com/leanprover/lake/issues/49
# ---

echo "# TEST 49"
MSGS="$INIT_REQ$INITD_NOT$SD_REQ$EXIT_NOT"
echo -n "$MSGS" | $LAKE serve > serve.log
echo "Test passed"

# ---
# Test that `lake setup-file` retains the error from `lake serve`
# See https://github.com/leanprover/lake/issues/116
# ---

echo "# TEST 116"

# Test that `lake setup-file` produces the error from `LAKE_INVALID_CONFIG`
(LAKE_INVALID_CONFIG=$'foo\n' $LAKE setup-file ./Irrelevant.theorem_ai 2>&1 && exit 1 || true) | grep --color foo

# Test that `lake serve` produces the `Failed to configure` message.
MSGS="$INIT_REQ$INITD_NOT$OPEN_REQ"
grep -q "Failed to configure the Lake workspace" <(set +e; (echo -n "$MSGS" && $TAIL --pid=$$ -f /dev/null) | timeout 30s $LAKE serve | tee serve.log)

echo "Test passed"
