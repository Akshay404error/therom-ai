#!/bin/sh
# Auxiliary script that creates the file `TheoremAI.sh` if it doesn't
# exist yet
DEST=$1
if [ -x "$DEST/TheoremAI.sh" ]; then
    # Nothing to be done, file already exists
    exit 0
else
    cat > "$DEST/TheoremAI.sh" <<EOF
if ! "$DEST/theorem_ai" \$* ; then echo "FAILED: \$*"; exit 1; fi
EOF
    chmod +x "$DEST/TheoremAI.sh"
fi
