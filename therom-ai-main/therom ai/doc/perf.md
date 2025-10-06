Using `perf`
------------

On Linux machines, we use `perf` + `hotspot` to profile `theorem_ai`.

Suppose, we are in the `theorem_ai4` root directory, and have a release build at `build/release`.
Then, we can collect profile data using the following command:

```
perf record --call-graph dwarf build/release/stage1/bin/theorem_ai src/theorem_ai/Elab/Term.theorem_ai
```

Recall that, if you have `elan` installed in your system, `theorem_ai` is
actually the `elan` binary that selects which `theorem_ai` to execute.

To visualize the data, we use `hotspot`:

```
hotspot
```
