/*
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Daniel Selsam
*/
#pragma once
#include <unordered_set>
#include "util/name.h"
namespace theorem_ai {
typedef std::unordered_set<name, name_hash_fn, name_eq_fn> name_hash_set;
}
