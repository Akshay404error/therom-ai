/*
Copyright (c) 2018 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#pragma once
#include <functional>
#include <vector>
#include "runtime/object.h"
#include "util/alloc.h"

namespace theorem_ai {
typedef lean_object * object_offset;

class LEAN_EXPORT object_compactor {
    struct max_sharing_table;
    friend struct max_sharing_hash;
    friend struct max_sharing_eq;
    theorem_ai::unordered_map<object*, object_offset, std::hash<object*>, std::equal_to<object*>> m_obj_table;
    std::unique_ptr<max_sharing_table> m_max_sharing_table;
    std::vector<object*> m_todo;
    std::vector<object_offset> m_tmp;
    // On-disk base address used for `mmap`ing compacted regions without relocations
    // References within the compacted region are rewritten by subtracting `m_begin` and adding `m_base_addr`
    // In the simplest case `base_addr == nullptr`, we get region-relative pointers
    void * m_base_addr;
    void * m_begin;
    void * m_end;
    void * m_capacity;
    size_t capacity() const { return static_cast<char*>(m_capacity) - static_cast<char*>(m_begin); }
    void save(object * o, object * new_o);
    void save_max_sharing(object * o, object * new_o, size_t new_o_sz);
    object_offset to_offset(object * o);
    void insert_terminator(object * o);
    object * copy_object(object * o);
    bool insert_constructor(object * o);
    bool insert_array(object * o);
    void insert_sarray(object * o);
    void insert_string(object * o);
    bool insert_thunk(object * o);
    bool insert_task(object * o);
    bool insert_promise(object * o);
    bool insert_ref(object * o);
    void insert_mpz(object * o);
public:
    object_compactor(void * base_addr = nullptr);
    object_compactor(object_compactor const &) = delete;
    object_compactor(object_compactor &&) = delete;
    ~object_compactor();
    object_compactor operator=(object_compactor const &) = delete;
    object_compactor operator=(object_compactor &&) = delete;
    void operator()(object * o);
    size_t size() const { return static_cast<char*>(m_end) - static_cast<char*>(m_begin); }
    void const * data() const { return m_begin; }
    void * alloc(size_t sz);
};

class LEAN_EXPORT compacted_region {
    size_t m_size;
    // see `object_compactor::m_base_addr`
    void * m_base_addr;
    bool m_is_mmap;
    std::function<void()> m_free_data;
    void * m_begin;
    void * m_next;
    void * m_end;
    void move(size_t d);
    void move(object * o);
    object * fix_object_ptr(object * o);
    void fix_constructor(object * o);
    void fix_array(object * o);
    void fix_thunk(object * o);
    void fix_ref(object * o);
    void fix_task(object * o);
    void fix_promise(object * o);
    void fix_mpz(object * o);
public:
    /* Creates a compacted object region using the given region in memory.
       This object takes ownership of the region. */
    compacted_region(size_t sz, void * data, void * base_addr, bool is_mmap, std::function<void()> free_data);
    /* Creates a compacted object region using the object_compactor current state.
       It creates a copy of the compacted region generated by the object compactor. */
    explicit compacted_region(object_compactor const & c);
    compacted_region(compacted_region const &) = delete;
    compacted_region(compacted_region &&) = delete;
    ~compacted_region();
    compacted_region operator=(compacted_region const &) = delete;
    compacted_region operator=(compacted_region &&) = delete;
    object * read();
    bool is_memory_mapped() const { return m_is_mmap; }
    size_t size() const { return m_size; }
};
}
