/*
Copyright (c) 2018 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#pragma once
#include "runtime/object.h"
namespace theorem_ai {
LEAN_EXPORT object * curry(void * f, unsigned n, object ** as);
}
