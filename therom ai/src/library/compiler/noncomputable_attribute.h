/*
Copyright (c) 2025 theorem_ai FRO, LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Cameron Zwarich
*/
#pragma once
#include "library/elab_environment.h"

namespace theorem_ai {
bool has_noncomputable_attribute(elab_environment const & env, name const & n);
}
