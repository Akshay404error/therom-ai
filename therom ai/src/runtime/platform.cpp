/*
Copyright (c) 2019 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include "util/macros.h"
#include "runtime/object.h"
#include "githash.h"

namespace theorem_ai {
extern "C" LEAN_EXPORT obj_res lean_system_platform_nbits(obj_arg) {
    if (sizeof(void*) == 8) {
        return box(64);
    } else {
        return box(32);
    }
}

extern "C" LEAN_EXPORT uint8 lean_system_platform_windows(obj_arg) {
#if defined(LEAN_WINDOWS)
    return 1;
#else
    return 0;
#endif
}

extern "C" LEAN_EXPORT uint8 lean_system_platform_osx(obj_arg) {
#if defined(__APPLE__)
    return 1;
#else
    return 0;
#endif
}

extern "C" LEAN_EXPORT uint8 lean_system_platform_emscripten(obj_arg) {
#if defined(LEAN_EMSCRIPTEN)
    return 1;
#else
    return 0;
#endif
}

extern "C" object * lean_get_githash(obj_arg) { return lean_mk_string(LEAN_GITHASH); }

extern "C" LEAN_EXPORT uint8 lean_internal_has_llvm_backend(obj_arg) {
#ifdef LEAN_LLVM
    return 1;
#else
    return 0;
#endif
}

extern "C" LEAN_EXPORT uint8 lean_internal_has_address_sanitizer(obj_arg) {
#if defined(__has_feature)
#if __has_feature(address_sanitizer)
    return 1;
#else
    return 0;
#endif
#else
    return 0;
#endif
}

extern "C" LEAN_EXPORT uint8 lean_internal_is_multi_thread(obj_arg) {
#ifdef LEAN_MULTI_THREAD
    return 1;
#else
    return 0;
#endif
}

extern "C" LEAN_EXPORT uint8 lean_internal_is_debug(obj_arg) {
#ifdef LEAN_DEBUG
    return 1;
#else
    return 0;
#endif
}

extern "C" LEAN_EXPORT obj_res lean_internal_get_build_type(obj_arg) {
    return mk_string(LEAN_STR(LEAN_BUILD_TYPE));
}
}
