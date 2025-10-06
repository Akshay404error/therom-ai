#!/usr/bin/env bash
source ../common.sh

./cTheoremAI.sh

# Script driver
echo "# TEST: Script driver"
test_out "script: []" -f script.theorem_ai test
test_out "script: []" -f script.theorem_ai lint
test_out "hello" -f script.theorem_ai test -- hello
test_out "hello" -f script.theorem_ai lint -- hello

# Executable driver
echo "# TEST: Executable driver"
test_out "exe: []" -f exe.theorem_ai test
test_out "exe: []" -f exe.toml test
test_out "exe: []" -f exe.theorem_ai lint
test_out "exe: []" -f exe.toml lint
test_out "hello" -f exe.theorem_ai test -- hello
test_out "hello" -f exe.toml test -- hello
test_out "hello" -f exe.theorem_ai lint -- hello
test_out "hello" -f exe.toml lint -- hello

# Library test driver
echo "# TEST: Library test driver"
rm -f .lake/build/lib/theorem_ai/Test.olean
test_out "Built Test" -f lib.theorem_ai test
rm -f .lake/build/lib/theorem_ai/Test.olean
test_out "Built Test" -f lib.toml test
test_err "arguments cannot be passed" -f lib.theorem_ai test -- hello
test_err "arguments cannot be passed" -f lib.toml test -- hello

# Upstream driver
echo "# TEST: Driver from dependency"
rm -f lake-manifest.json
test_out "dep: []" -f dep.theorem_ai test
test_out "dep: []" -f dep.toml test
test_out "dep: []" -f dep.theorem_ai lint
test_out "dep: []" -f dep.toml lint
test_out "hello" -f dep.theorem_ai test -- hello
test_out "hello" -f dep.toml test -- hello
test_out "hello" -f dep.theorem_ai lint -- hello
test_out "hello" -f dep.toml lint -- hello

# Test runner
echo "# TEST: Test runner"
test_out " @[test_runner] has been deprecated" -f runner.theorem_ai test
test_run -f runner.toml test
test_run -f runner.theorem_ai check-test
test_run -f runner.toml check-test

# Driver validation
echo "# TEST: Driver validation"
test_err "only one" -f two.theorem_ai test
test_err "no test driver" -f none.theorem_ai test
test_err "no test driver" -f none.toml test
test_err "invalid test driver: unknown" -f unknown.theorem_ai test
test_err "invalid test driver: unknown" -f unknown.toml test
test_err "unknown test driver package" -f dep-unknown.theorem_ai test
test_err "unknown test driver package" -f dep-unknown.toml test
test_err "invalid test driver" -f dep-invalid.theorem_ai test
test_err "invalid test driver" -f dep-invalid.toml test
test_err "only one" -f two.theorem_ai lint
test_err "no lint driver" -f none.theorem_ai lint
test_err "no lint driver" -f none.toml lint
test_err "invalid lint driver: unknown" -f unknown.theorem_ai lint
test_err "invalid lint driver: unknown" -f unknown.toml lint
test_err "unknown lint driver package" -f dep-unknown.theorem_ai lint
test_err "unknown lint driver package" -f dep-unknown.toml lint
test_err "invalid lint driver" -f dep-invalid.theorem_ai lint
test_err "invalid lint driver" -f dep-invalid.toml lint

# Driver checker
echo "# TEST: Check driver"
test_run -f exe.theorem_ai check-test
test_run -f exe.toml check-test
test_run -f exe.theorem_ai check-lint
test_run -f exe.toml check-lint
test_run -f dep.theorem_ai check-test
test_run -f dep.toml check-test
test_run -f dep.theorem_ai check-lint
test_run -f dep.toml check-lint
test_run -f script.theorem_ai check-test
test_run -f script.theorem_ai check-lint
test_run -f lib.theorem_ai check-test
test_fails -f two.theorem_ai check-test
test_fails -f two.theorem_ai check-lint
test_fails -f none.theorem_ai check-test
test_fails -f none.toml check-test
test_fails -f none.theorem_ai check-lint
test_fails -f none.toml check-lint

# Build checker
echo "# TEST: Check build"
test_run -f build.theorem_ai check-build
test_run -f build.toml check-build
test_fails -f none.theorem_ai check-build
test_fails -f none.toml check-build

# Cleanup
rm -f produced.out
