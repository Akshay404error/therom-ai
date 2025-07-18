#include "util/options.h"

namespace theorem_ai {
options get_default_options() {
    options opts;
    // see https://github.com/leanprover/theorem_ai4/blob/master/doc/dev/bootstrap.md#further-bootstrapping-complications
#if LEAN_IS_STAGE0 == 1
    // set to true to generally avoid bootstrapping issues limited to proofs
    opts = opts.update({"debug", "proofAsSorry"}, false);
    // set to true to generally avoid bootstrapping issues in `omega` and `grind`
    opts = opts.update({"debug", "terminalTacticsAsSorry"}, false);
    // switch to `true` for ABI-breaking changes affecting meta code;
    // see also next option!
    opts = opts.update({"interpreter", "prefer_native"}, false);
    // switch to `false` when enabling `prefer_native` should also affect use
    // of built-in parsers in quotations; this is usually the case, but setting
    // both to `true` may be necessary for handling non-builtin parsers with
    // builtin elaborators
    opts = opts.update({"internal", "parseQuotWithCurrentStage"}, true);
    // changes to builtin parsers may also require toggling the following option if macros/syntax
    // with custom precheck hooks were affected
    opts = opts.update({"quotPrecheck"}, true);

    opts = opts.update({"pp", "rawOnError"}, true);
#endif
    return opts;
}
}
