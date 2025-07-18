/*
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#pragma once

namespace theorem_ai {
void initialize();
void finalize();
/** \brief Helper object for initializing theorem_ai */
class initializer {
public:
    initializer();
    ~initializer();
};
}
