set -ex

LAKE=${LAKE:-../../.lake/build/bin/lake}

./cTheoremAI.sh

LAKE=$LAKE make run
LAKE=$LAKE make run-local
