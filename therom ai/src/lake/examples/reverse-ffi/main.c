#include <stdio.h>
#include <theorem_ai/TheoremAI.h>

extern uint64_t my_length(lean_obj_arg);

// see https://theorem-ai.org/doc/reference/latest/find/?domain=Verso.Genre.Manual.section&name=ffi-initialization
extern void lean_initialize_runtime_module();
extern void lean_initialize();
extern void lean_io_mark_end_initialization();
extern lean_object * initialize_RFFI(uint8_t builtin, lean_object *);

int main() {
  lean_initialize_runtime_module();
  lean_object * res;
  // use same default as for theorem_ai executables
  uint8_t builtin = 1;
  res = initialize_RFFI(builtin, lean_io_mk_world());
  if (lean_io_result_is_ok(res)) {
      lean_dec_ref(res);
  } else {
      lean_io_result_show_error(res);
      lean_dec(res);
      return 1;  // do not access theorem_ai declarations if initialization failed
  }
  lean_io_mark_end_initialization();

  // actual program

  lean_object * s = lean_mk_string("hello!");
  uint64_t l = my_length(s);
  printf("output: %ld\n", l);
}
