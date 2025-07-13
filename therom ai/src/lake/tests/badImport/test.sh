#!/usr/bin/env bash
source ../common.sh

./cTheoremAI.sh

# Test that failed imports show the module that imported them
# https://github.com/leanprover/lake/issues/25
# https://github.com/leanprover/theorem_ai4/issues/2569
# https://github.com/leanprover/theorem_ai4/issues/2415
# https://github.com/leanprover/theorem_ai4/issues/3351
# https://github.com/leanprover/theorem_ai4/issues/3809

# Test a module with a bad import does not kill the whole build
test_err "Building Etc" build Lib.U Etc
# Test importing a missing module from outside the workspace
test_err "U.theorem_ai:2:0: unknown module prefix 'Bogus'" build +Lib.U
test_err "U.theorem_ai:2:0: error: unknown module prefix 'Bogus'" theorem_ai ./Lib/U.theorem_ai
test_run setup-file ./Lib/U.theorem_ai # Lake ignores the unknown import (the server will error)
# Test importing oneself
test_err "S.theorem_ai: module imports itself" build +Lib.S
test_err "S.theorem_ai: module imports itself" theorem_ai ./Lib/S.theorem_ai
test_err "S.theorem_ai: module imports itself" setup-file ./Lib/S.theorem_ai
# Test importing a missing module from within the workspace
test_err "B.theorem_ai: bad import 'Lib.Bogus'" build +Lib.B
test_err "B.theorem_ai: bad import 'Lib.Bogus'" theorem_ai ./Lib/B.theorem_ai
test_err "B.theorem_ai: bad import 'Lib.Bogus'" setup-file ./Lib/B.theorem_ai
# Test a vanishing import within the workspace (theorem_ai4#3551)
echo "# TEST: Vanishing Import"
test_cmd touch Lib/Bogus.theorem_ai
test_run build +Lib.B
test_cmd rm Lib/Bogus.theorem_ai
test_err "B.theorem_ai: bad import 'Lib.Bogus'" build +Lib.B
test_err "B.theorem_ai: bad import 'Lib.Bogus'" theorem_ai ./Lib/B.theorem_ai
test_err "B.theorem_ai: bad import 'Lib.Bogus'" setup-file ./Lib/B.theorem_ai
# Test a module which imports a module containing a bad import
test_err "B1.theorem_ai: bad import 'Lib.B'" build +Lib.B1
test_err "B1.theorem_ai: bad import 'Lib.B'" theorem_ai ./Lib/B1.theorem_ai
test_err "B1.theorem_ai: bad import 'Lib.B'" setup-file ./Lib/B1.theorem_ai
# Test an executable with a bad import does not kill the whole build
test_err "Building Etc" build X Etc
# Test an executable which imports a missing module from within the workspace
test_err "X.theorem_ai: bad import 'Lib.Bogus'" build X
# Test an executable which imports a module containing a bad import
test_err "B.theorem_ai: bad import 'Lib.Bogus'" build X1

# Cleanup
rm -f produced.out
