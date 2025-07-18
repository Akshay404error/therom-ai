/*
Copyright (c) 2018 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#pragma once
#include "library/elab_environment.h"
#include "library/compiler/util.h"
namespace theorem_ai {
/** \brief Lift lambda expressions in `ds`. The result also contains new auxiliary declarations that have been generated. */
pair<elab_environment, comp_decls> lambda_lifting(elab_environment env, comp_decls const & ds);
/* Return true iff `fn` is the name of an auxiliary function generated by `lambda_lifting`. */
bool is_lambda_lifting_name(name fn);
};
