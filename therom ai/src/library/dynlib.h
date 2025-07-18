/*
Copyright (c) 2021 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Mac Malone
*/
#pragma once
#include <string>

namespace theorem_ai {
LEAN_EXPORT void initialize_dynlib();
LEAN_EXPORT void load_dynlib(std::string path);
LEAN_EXPORT void load_plugin(std::string path);
}
