#!/usr/bin/env bash
set -euo pipefail

# Test that theorem_ai will use the specified olean from `setup.json`
theorem_ai Dep.theorem_ai -o Dep.olean
theorem_ai Test.theorem_ai --setup setup.json
