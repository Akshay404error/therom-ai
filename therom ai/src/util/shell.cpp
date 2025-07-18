/*
Copyright (c) 2013 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include <iostream>
#include <fstream>
#include <signal.h>
#include <cctype>
#include <cstdlib>
#include <string>
#include <utility>
#include <vector>
#include <set>
#include "runtime/stackinfo.h"
#include "runtime/interrupt.h"
#include "runtime/memory.h"
#include "runtime/thread.h"
#include "runtime/debug.h"
#include "runtime/sstream.h"
#include "runtime/array_ref.h"
#include "runtime/object_ref.h"
#include "runtime/option_ref.h"
#include "runtime/utf8.h"
#include "util/timer.h"
#include "util/macros.h"
#include "util/io.h"
#include "util/options.h"
#include "util/option_declarations.h"
#include "library/elab_environment.h"
#include "kernel/kernel_exception.h"
#include "kernel/trace.h"
#include "library/dynlib.h"
#include "library/formatter.h"
#include "library/module.h"
#include "library/time_task.h"
#include "library/compiler/ir.h"
#include "library/print.h"
#include "initialize/init.h"
#include "library/compiler/ir_interpreter.h"
#include "util/path.h"
#include "stdlib_flags.h"
#ifdef _MSC_VER
#include <io.h>
#define STDOUT_FILENO 1
#else
#include <getopt.h>
#include <unistd.h>
#endif
#if defined(LEAN_EMSCRIPTEN)
#include <emscripten.h>
#endif
#include "githash.h" // NOLINT

#ifdef LEAN_WINDOWS
#include <windows.h>
#endif

#ifdef _MSC_VER
// extremely simple implementation of getopt.h
enum arg_opt { no_argument, required_argument, optional_argument };

struct option {
    const char name[20];
    arg_opt has_arg;
    int *flag;
    char val;
};

static char *optarg;
static int optind = 1;

int getopt_long(int argc, char *in_argv[], const char *optstring, const option *opts, int *index) {
    optarg = nullptr;
    if (optind >= argc)
        return -1;

    char *argv = in_argv[optind];
    if (argv[0] != '-') {
        // find first -opt if any
        int i = optind;
        bool found = false;
        for (; i < argc; ++i) {
            if (in_argv[i][0] == '-') {
                found = true;
                break;
            }
        }
        if (!found)
            return -1;
        auto next = in_argv[i];
        // FIXME: this doesn't account for long options with arguments like --foo arg
        memmove(&in_argv[optind + 1], &in_argv[optind], (i - optind) * sizeof(argv));
        argv = in_argv[optind] = next;
    }
    ++optind;

    // long option
    if (argv[1] == '-') {
        auto eq = strchr(argv, '=');
        size_t sz = (eq ? (eq - argv) : strlen(argv)) - 2;
        for (auto I = opts; *I->name; ++I) {
            if (!strncmp(I->name, argv + 2, sz) && I->name[sz] == '\0') {
                assert(!I->flag);
                switch (I->has_arg) {
                case no_argument:
                    if (eq) {
                        std::cerr << in_argv[0] << ": option doesn't take an argument -- " << I->name << std::endl;
                        return '?';
                    }
                    break;
                case required_argument:
                    if (eq) {
                        optarg = eq + 1;
                    } else {
                        if (optind >= argc) {
                            std::cerr << in_argv[0] << ": option requires an argument -- " << I->name << std::endl;
                            return '?';
                        }
                        optarg = in_argv[optind++];
                    }
                    break;
                case optional_argument:
                    if (eq) {
                        optarg = eq + 1;
                    }
                    break;
                }
                if (index)
                  *index = I - opts;
                return I->val;
            }
        }
        return '?';
    } else {
        auto opt = strchr(optstring, argv[1]);
        if (!opt)
            return '?';

        if (opt[1] == ':') {
            if (argv[2] == '\0') {
                if (optind < argc) {
                    optarg = in_argv[optind++];
                } else {
                    std::cerr << in_argv[0] << ": option requires an argument -- " << *opt << std::endl;
                    return '?';
                }
            } else {
                optarg = argv + 2;
            }
        }
        return *opt;
    }
}
#endif

using namespace theorem_ai; // NOLINT

#ifndef LEAN_SERVER_DEFAULT_MAX_MEMORY
#define LEAN_SERVER_DEFAULT_MAX_MEMORY 1024
#endif
#ifndef LEAN_DEFAULT_MAX_MEMORY
#define LEAN_DEFAULT_MAX_MEMORY 0
#endif
#ifndef LEAN_DEFAULT_MAX_HEARTBEAT
#define LEAN_DEFAULT_MAX_HEARTBEAT 0
#endif
#ifndef LEAN_SERVER_DEFAULT_MAX_HEARTBEAT
#define LEAN_SERVER_DEFAULT_MAX_HEARTBEAT 100000
#endif

extern "C" obj_res lean_display_header(obj_arg);
static void display_header() {
    consume_io_result(lean_display_header(io_mk_world()));
}

static void display_version(std::ostream & out) {
    out << get_short_version_string() << "\n";
}

static void display_features(std::ostream & out) {
    out << "[";
#if defined(LEAN_LLVM)
    out << "LLVM";
#endif
    out << "]\n";
}

extern "C" obj_res lean_display_help(uint8 use_stderr, obj_arg);
static void display_help(bool use_stderr) {
    consume_io_result(lean_display_help(use_stderr, io_mk_world()));
}

static int only_src_deps = 0;
static int print_prefix = 0;
static int print_libdir = 0;
static int json_output = 0;

static struct option g_long_options[] = {
    {"version",      no_argument,       0, 'v'},
    {"help",         no_argument,       0, 'h'},
    {"githash",      no_argument,       0, 'g'},
    {"short-version", no_argument,      0, 'V'},
    {"run",          no_argument,       0, 'r'},
    {"o",            optional_argument, 0, 'o'},
    {"i",            optional_argument, 0, 'i'},
    {"stdin",        no_argument,       0, 'I'},
    {"root",         required_argument, 0, 'R'},
    {"memory",       required_argument, 0, 'M'},
    {"trust",        required_argument, 0, 't'},
    {"profile",      no_argument,       0, 'P'},
    {"stats",        no_argument,       0, 'a'},
    {"quiet",        no_argument,       0, 'q'},
    {"deps",         no_argument,       0, 'd'},
    {"src-deps",     no_argument,       &only_src_deps, 1},
    {"deps-json",    no_argument,       0, 'J'},
    {"timeout",      optional_argument, 0, 'T'},
    {"c",            optional_argument, 0, 'c'},
    {"bc",           optional_argument, 0, 'b'},
    {"features",     optional_argument, 0, 'f'},
    {"exitOnPanic",  no_argument,       0, 'e'},
#if defined(LEAN_MULTI_THREAD)
    {"threads",      required_argument, 0, 'j'},
    {"tstack",       required_argument, 0, 's'},
    {"server",       no_argument,       0, 'S'},
    {"worker",       no_argument,       0, 'W'},
#endif
    {"plugin",       required_argument, 0, 'p'},
    {"load-dynlib",  required_argument, 0, 'l'},
    {"setup",        required_argument, 0, 'u'},
    {"error",        required_argument, 0, 'E'},
    {"json",         no_argument,       &json_output, 1},
    {"print-prefix", no_argument,       &print_prefix, 1},
    {"print-libdir", no_argument,       &print_libdir, 1},
#ifdef LEAN_DEBUG
    {"debug",        required_argument, 0, 'B'},
#endif
    {0, 0, 0, 0}
};

static char const * g_opt_str =
    "PdD:o:i:b:c:C:qgvVht:012j:012rR:M:012T:012ap:eE:"
#if defined(LEAN_MULTI_THREAD)
    "s:012"
#endif
; // NOLINT

options set_config_option(options const & opts, char const * in) {
    if (!in) return opts;
    while (*in && std::isspace(*in))
        ++in;
    std::string in_str(in);
    auto pos = in_str.find('=');
    if (pos == std::string::npos)
        throw theorem_ai::exception("invalid -D parameter, argument must contain '='");
    theorem_ai::name opt = theorem_ai::string_to_name(in_str.substr(0, pos));
    std::string val = in_str.substr(pos+1);
    auto decls = theorem_ai::get_option_declarations();
    auto it = decls.find(opt);
    if (it) {
        switch (it->kind()) {
        case theorem_ai::data_value_kind::Bool:
            if (val == "true")
                return opts.update(opt, true);
            else if (val == "false")
                return opts.update(opt, false);
            else
                throw theorem_ai::exception(theorem_ai::sstream() << "invalid -D parameter, invalid configuration option '" << opt
                                      << "' value, it must be true/false");
        case theorem_ai::data_value_kind::Nat:
            return opts.update(opt, static_cast<unsigned>(atoi(val.c_str())));
        case theorem_ai::data_value_kind::String:
            return opts.update(opt, val.c_str());
        default:
            throw theorem_ai::exception(theorem_ai::sstream() << "invalid -D parameter, configuration option '" << opt
                                  << "' cannot be set in the command line, use set_option command");
        }
    } else {
        // More options may be registered by imports, so we leave validating them to the theorem_ai side.
        // This (minor) duplication will be resolved when this file is rewritten in TheoremAI.
        return opts.update(opt, val.c_str());
    }
}

namespace theorem_ai {
extern "C" obj_res lean_shell_main(
    obj_arg  args,
    uint8    use_stdin,
    uint8    only_deps,
    uint8    only_src_deps,
    uint8    deps_json,
    obj_arg  opts,
    uint32_t trust_level,
    obj_arg  root_dir,
    obj_arg  setup_file_name,
    obj_arg  olean_filename,
    obj_arg  ilean_filename,
    obj_arg  c_filename,
    obj_arg  bc_filename,
    uint8    json_output,
    obj_arg  error_kinds,
    uint8    print_stats,
    uint8    run,
    obj_arg  w
);
uint32 run_shell_main(
    int argc, char* argv[],
    bool use_stdin,
    bool only_deps,
    bool only_src_deps,
    bool deps_json,
    options const & opts,
    uint32_t trust_level,
    optional<std::string> const & root_dir,
    optional<std::string> const & setup_file_name,
    optional<std::string> const & olean_file_name,
    optional<std::string> const & ilean_file_name,
    optional<std::string> const & c_file_name,
    optional<std::string> const & bc_file_name,
    bool json_output,
    array_ref<name> const & error_kinds,
    bool print_stats,
    bool run
) {
    list_ref<string_ref> args;
    while (argc > 0) {
        argc--;
        args = list_ref<string_ref>(string_ref(argv[argc]), args);
    }
    return get_io_scalar_result<uint32>(lean_shell_main(
        args.steal(),
        use_stdin,
        only_deps, only_src_deps, deps_json,
        opts.to_obj_arg(),
        trust_level,
        root_dir ? mk_option_some(mk_string(*root_dir)) : mk_option_none(),
        setup_file_name ? mk_option_some(mk_string(*setup_file_name)) : mk_option_none(),
        olean_file_name ? mk_option_some(mk_string(*olean_file_name)) : mk_option_none(),
        ilean_file_name ? mk_option_some(mk_string(*ilean_file_name)) : mk_option_none(),
        c_file_name ? mk_option_some(mk_string(*c_file_name)) : mk_option_none(),
        bc_file_name ? mk_option_some(mk_string(*bc_file_name)) : mk_option_none(),
        json_output,
        error_kinds.to_obj_arg(),
        print_stats,
        run,
        io_mk_world()
    ));
}

/* def workerMain : Options → IO UInt32 */
extern "C" object * lean_server_worker_main(object * opts, object * w);
uint32_t run_server_worker(options const & opts) {
    return get_io_scalar_result<uint32_t>(lean_server_worker_main(opts.to_obj_arg(), io_mk_world()));
}

/* def watchdogMain (args : List String) : IO Uint32 */
extern "C" object* lean_server_watchdog_main(object* args, object* w);
uint32_t run_server_watchdog(buffer<string_ref> const & args) {
    list_ref<string_ref> arglist = to_list_ref(args);
    return get_io_scalar_result<uint32_t>(lean_server_watchdog_main(arglist.to_obj_arg(), io_mk_world()));
}

extern "C" object* lean_init_search_path(object* w);
void init_search_path() {
    get_io_scalar_result<unsigned>(lean_init_search_path(io_mk_world()));
}

extern "C" object* lean_environment_free_regions(object * env, object * w);
void environment_free_regions(elab_environment && env) {
    consume_io_result(lean_environment_free_regions(env.steal(), io_mk_world()));
}
}

extern "C" object * lean_get_prefix(object * w);
extern "C" object * lean_get_libdir(object * sysroot, object * w);

void check_optarg(char const * option_name) {
    if (!optarg) {
        std::cerr << "error: argument missing for option '-" << option_name << "'" << std::endl;
        std::exit(1);
    }
}

extern "C" object * lean_enable_initializer_execution(object * w);

namespace theorem_ai {
extern void (*g_lean_report_task_get_blocked_time)(std::chrono::nanoseconds);
}
static bool trace_task_get_blocked = getenv("LEAN_TRACE_TASK_GET_BLOCKED") != nullptr;
static void report_task_get_blocked_time(std::chrono::nanoseconds d) {
    if (has_no_block_profiling_task()) {
        report_profiling_time("blocked (unaccounted)", d);
        exclude_profiling_time_from_current_task(d);
        if (trace_task_get_blocked) {
            sstream ss;
            ss << "Task.get blocked for " << std::chrono::duration_cast<std::chrono::duration<float, std::milli>>(d).count() << "ms";
            // using a panic for reporting is a bit of a hack, but good enough for this
            // `theorem_ai`-specific use case
            lean_panic(ss.str().c_str(), /* force stderr */ true);
        }
    }
}

extern "C" LEAN_EXPORT int lean_main(int argc, char ** argv) {
#ifdef LEAN_EMSCRIPTEN
    // When running in command-line mode under Node.js, we make system directories available in the virtual filesystem.
    // This mode is used to compile 32-bit oleans.
    EM_ASM(
        if ((typeof process === "undefined") || (process.release.name !== "node")) {
            throw new Error("The theorem_ai command-line driver can only run under Node.js. For the embeddable WASM library, see lean_wasm.cpp.");
        }

        var lean_path = process.env["LEAN_PATH"];
        if (lean_path) {
            ENV["LEAN_PATH"] = lean_path;
        }

        // We cannot mount /, see https://github.com/emscripten-core/emscripten/issues/2040
        FS.mount(NODEFS, { root: "/home" }, "/home");
        FS.mount(NODEFS, { root: "/tmp" }, "/tmp");
        FS.chdir(process.cwd());
    );
#elif defined(LEAN_WINDOWS)
    // "best practice" according to https://docs.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-seterrormode
    SetErrorMode(SEM_FAILCRITICALERRORS);
    // properly formats Unicode characters on the Windows console
    // see https://github.com/leanprover/theorem_ai4/issues/4291
    SetConsoleOutputCP(CP_UTF8);
#endif
    auto init_start = std::chrono::steady_clock::now();
    theorem_ai::initializer init;
    second_duration init_time = std::chrono::steady_clock::now() - init_start;
    bool run = false;
    optional<std::string> olean_fn;
    optional<std::string> ilean_fn;
    optional<std::string> setup_fn;
    bool use_stdin = false;
    unsigned trust_lvl = LEAN_BELIEVER_TRUST_LEVEL + 1;
    bool only_deps = false;
    bool deps_json = false;
    bool stats = false;
    // 0 = don't run server, 1 = watchdog, 2 = worker
    int run_server = 0;
    unsigned num_threads    = 0;
#if defined(LEAN_MULTI_THREAD)
    num_threads = hardware_concurrency();
#endif

    try {
        // Remark: This currently runs under `IO.initializing = true`.
        init_search_path();
    } catch (theorem_ai::throwable & ex) {
        std::cerr << "error: " << ex.what() << std::endl;
        return 1;
    }
    consume_io_result(lean_enable_initializer_execution(io_mk_world()));

    options opts = get_default_options();
    optional<std::string> c_output;
    optional<std::string> llvm_output;
    optional<std::string> root_dir;
    buffer<string_ref> forwarded_args;
    buffer<name> error_kinds;

    while (!run) {  // stop consuming arguments after `--run`
        int c = getopt_long(argc, argv, g_opt_str, g_long_options, NULL);
        if (c == -1)
            break; // end of command line
        if (c == 0)
            continue; // long-only option
        switch (c) {
            case 'e':
                lean_set_exit_on_panic(true);
                break;
            case 'j':
                num_threads = static_cast<unsigned>(atoi(optarg));
                forwarded_args.push_back(string_ref("-j" + std::string(optarg)));
                break;
            case 'v':
                display_header();
                return 0;
            case 'V':
                display_version(std::cout);
                return 0;
            case 'g':
                std::cout << LEAN_GITHASH << "\n";
                return 0;
            case 'h':
                display_help(/* useStderr */ false);
                return 0;
            case 'f':
                display_features(std::cout);
                return 0;
            case 'c':
                check_optarg("c");
                c_output = optarg;
                break;
            case 'b':
                check_optarg("bc");
                llvm_output = optarg;
                break;
            case 's':
                theorem_ai::lthread::set_thread_stack_size(
                        static_cast<size_t>((atoi(optarg) / 4) * 4) * static_cast<size_t>(1024));
                forwarded_args.push_back(string_ref("-s" + std::string(optarg)));
                break;
            case 'I':
                use_stdin = true;
                break;
            case 'r':
                run = true;
                break;
            case 'o':
                olean_fn = optarg;
                break;
            case 'i':
                ilean_fn = optarg;
                break;
            case 'R':
                root_dir = optarg;
                forwarded_args.push_back(string_ref("-R" + std::string(optarg)));
                break;
            case 'M':
                check_optarg("M");
                opts = opts.update(get_max_memory_opt_name(), static_cast<unsigned>(atoi(optarg)));
                forwarded_args.push_back(string_ref("-M" + std::string(optarg)));
                break;
            case 'T':
                check_optarg("T");
                opts = opts.update(get_timeout_opt_name(), static_cast<unsigned>(atoi(optarg)));
                forwarded_args.push_back(string_ref("-T" + std::string(optarg)));
                break;
            case 't':
                check_optarg("t");
                trust_lvl = atoi(optarg);
                forwarded_args.push_back(string_ref("-t" + std::string(optarg)));
                break;
            case 'q':
                opts = opts.update(theorem_ai::get_verbose_opt_name(), false);
                break;
            case 'd':
                only_deps = true;
                break;
            case 'J':
                only_deps = true;
                deps_json = true;
                break;
            case 'a':
                stats = true;
                break;
            case 'D':
                try {
                    check_optarg("D");
                    opts = set_config_option(opts, optarg);
                    forwarded_args.push_back(string_ref("-D" + std::string(optarg)));
                } catch (theorem_ai::exception & ex) {
                    std::cerr << ex.what() << std::endl;
                    return 1;
                }
                break;
            case 'S':
                run_server = 1;
                break;
            case 'W':
                run_server = 2;
                break;
            case 'P':
                opts = opts.update("profiler", true);
                break;
#if defined(LEAN_DEBUG)
            case 'B':
                check_optarg("B");
                theorem_ai::enable_debug(optarg);
                break;
#endif
            case 'p':
                check_optarg("p");
                theorem_ai::load_plugin(optarg);
                forwarded_args.push_back(string_ref("--plugin=" + std::string(optarg)));
                break;
            case 'l':
                check_optarg("l");
                theorem_ai::load_dynlib(optarg);
                forwarded_args.push_back(string_ref("--load-dynlib=" + std::string(optarg)));
                break;
            case 'u':
                check_optarg("u");
                setup_fn = optarg;
                break;
            case 'E':
                check_optarg("E");
                error_kinds.push_back(string_to_name(std::string(optarg)));
                break;
            default:
                std::cerr << "Unknown command line option\n";
                display_help(/* useStderr */ true);
                return 1;
        }
    }

    theorem_ai::io_mark_end_initialization();

    if (print_prefix) {
        std::cout << get_io_result<string_ref>(lean_get_prefix(io_mk_world())).data() << std::endl;
        return 0;
    }

    if (print_libdir) {
        string_ref prefix = get_io_result<string_ref>(lean_get_prefix(io_mk_world()));
        std::cout << get_io_result<string_ref>(lean_get_libdir(prefix.to_obj_arg(), io_mk_world())).data() << std::endl;
        return 0;
    }

    if (auto max_memory = opts.get_unsigned(get_max_memory_opt_name(),
                                            opts.get_bool("server") ? LEAN_SERVER_DEFAULT_MAX_MEMORY
                                                                    : LEAN_DEFAULT_MAX_MEMORY)) {
        set_max_memory_megabyte(max_memory);
    }

    if (auto timeout = opts.get_unsigned(get_timeout_opt_name(),
                                         opts.get_bool("server") ? LEAN_SERVER_DEFAULT_MAX_HEARTBEAT
                                                                 : LEAN_DEFAULT_MAX_HEARTBEAT)) {
        set_max_heartbeat_thousands(timeout);
    }

    if (get_profiler(opts)) {
        g_lean_report_task_get_blocked_time = report_task_get_blocked_time;
        report_profiling_time("initialization", init_time);
    }

    scoped_task_manager scope_task_man(num_threads);

    try {
        if (run_server == 1)
            return run_server_watchdog(forwarded_args);
        else if (run_server == 2)
            return run_server_worker(opts);
        else
            return run_shell_main(
                argc - optind, argv + optind,
                use_stdin, only_deps, only_src_deps, deps_json,
                opts, trust_lvl, root_dir, setup_fn,
                olean_fn, ilean_fn, c_output, llvm_output,
                json_output, error_kinds, stats, run
            );
    } catch (theorem_ai::throwable & ex) {
        std::cerr << ex.what() << "\n";
    } catch (std::bad_alloc & ex) {
        std::cerr << "out of memory" << std::endl;
    }
    return 1;
}
