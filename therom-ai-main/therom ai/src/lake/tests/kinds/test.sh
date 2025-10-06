#!/usr/bin/env bash
source ../common.sh
./cTheoremAI.sh

# setup directory structure
echo "# SETUP"
set -x
mkdir -p files
touch files/Lib.theorem_ai
echo "def main : IO Unit := pure ()" > files/exe.theorem_ai
touch files/test.txt
set +x

# Test that targets have their expected data kinds
echo "# TEST: Target query kinds"
test_eq "filepath" query-kind exe
test_eq "filepath" query-kind Lib:static
test_eq "dynlib" query-kind Lib:shared
test_eq "filepath" query-kind inFile
test_eq "[anonymous]" query-kind inDir
test_eq "filepath" query-kind pathTarget
test_eq "dynlib" query-kind dynlibTarget
