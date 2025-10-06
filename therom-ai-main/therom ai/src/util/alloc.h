/*
Copyright (c) 2025 theorem_ai FRO. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Authors: Sebastian Ullrich
*/
#pragma once
#include <theorem_ai/config.h>
#include <unordered_map>
#include <unordered_set>

#ifdef LEAN_MIMALLOC
#include <theorem_ai/mimalloc.h>
#endif

namespace theorem_ai {

// We do not override `new` to avoid FFI issues for users but use `theorem_ai::allocator`
// explicitly where using the custom allocator is important.

#ifdef LEAN_MIMALLOC
template<class T> using allocator = mi_stl_allocator<T>;
#else
template<class T> using allocator = std::allocator<T>;
#endif

// `unordered_map/set` allocates per insert, so specializing to the custom allocator can
// save significant time for maps with frequent inserts.

template<
    class Key,
    class T,
    class Hash = std::hash<Key>,
    class KeyEqual = std::equal_to<Key>,
    class Allocator = theorem_ai::allocator<std::pair<const Key, T>>
> using unordered_map = std::unordered_map<Key, T, Hash, KeyEqual, Allocator>;

template<
    class Key,
    class Hash = std::hash<Key>,
    class KeyEqual = std::equal_to<Key>,
    class Allocator = theorem_ai::allocator<Key>
> using unordered_set = std::unordered_set<Key, Hash, KeyEqual, Allocator>;
};
