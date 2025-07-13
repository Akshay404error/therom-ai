#!/usr/bin/env bash
source ../common.sh

./cTheoremAI.sh

# Test theorem_ai to TOML translation
test_no_out translate-config -f source.theorem_ai toml out.produced.toml
test_cmd diff --strip-trailing-cr out.expected.toml out.produced.toml
test_cmd rm out.produced.toml

# Test idempotency of TOML translation
test_no_out translate-config -f out.expected.toml toml out.produced.toml
test_cmd diff --strip-trailing-cr out.expected.toml out.produced.toml

# Test TOML to theorem_ai translation
test_no_out translate-config -f source.toml theorem_ai out.produced.theorem_ai
test_cmd diff --strip-trailing-cr out.expected.theorem_ai out.produced.theorem_ai
test_cmd rm out.produced.theorem_ai

# Test idempotency of theorem_ai translation
test_no_out translate-config -f out.expected.theorem_ai theorem_ai out.produced.theorem_ai
test_cmd diff --strip-trailing-cr out.expected.theorem_ai out.produced.theorem_ai

# Test produced TOML round-trips
test_no_out translate-config -f out.produced.toml theorem_ai bridge.produced.theorem_ai
test_no_out translate-config -f bridge.produced.theorem_ai toml roundtrip.produced.toml
test_cmd diff --strip-trailing-cr out.produced.toml roundtrip.produced.toml

# Test produced theorem_ai round-trips
test_no_out translate-config -f out.produced.theorem_ai toml bridge.produced.toml
test_no_out translate-config -f bridge.produced.toml theorem_ai roundtrip.produced.theorem_ai
test_cmd diff --strip-trailing-cr out.produced.theorem_ai roundtrip.produced.theorem_ai

# Test source rename
test_cmd cp source.theorem_ai lakefile.theorem_ai
test_no_out translate-config toml
test_exp -f lakefile.TheoremAI.bak
test_exp -f lakefile.toml

# Cleanup
rm -f produced.out
