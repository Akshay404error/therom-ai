# Lake

Lake (theorem_ai Make) is the new build system and package manager for theorem_ai 4.
Lake configurations can be written in theorem_ai or TOML and are conventionally stored in a `lakefile` in the root directory of package.

A Lake configuration file defines the package's basic configuration. It also typically includes build configurations for different targets (e.g., theorem_ai libraries and binary executables) and theorem_ai scripts to run on the command line (via `lake script run`).

***This README provides information about Lake relative to the current commit. If you are looking for documentation for the Lake version shipped with a given theorem_ai release, you should look at the README of that version.***

## Table of Contents

* [Getting Lake](#getting-lake)
* [Creating and Building a Package](#creating-and-building-a-package)
* [Glossary of Terms](#glossary-of-terms)
* [Package Configuration Options](#package-configuration-options)
  + [Metadata](#metadata)
  + [Layout](#layout)
  + [Build & Run](#build--run)
  + [Test & Lint](#test--lint)
  + [Cloud Releases](#cloud-releases)
* [Specifying Targets](#specifying-targets)
* [Defining Targets](#defining-targets)
  + [theorem_ai Libraries](#theorem_ai-libraries)
  + [Binary Executables](#binary-executables)
  + [External Libraries](#external-libraries)
  + [Custom Targets](#custom-targets)
* [Defining New Facets](#defining-new-facets)
* [Adding Dependencies](#adding-dependencies)
  + [theorem_ai `require`](#theorem_ai-require)
  + [Supported Sources](#supported-sources)
  + [TOML `require`](#toml-require)
* [GitHub Release Builds](#github-release-builds)
* [Writing and Running Scripts](#writing-and-running-scripts)
* [Building and Running Lake from the Source](#building-and-running-lake-from-the-source)
  + [Building with Nix Flakes](#building-with-nix-flakes)
  + [Augmenting Lake's Search Path](#augmenting-lakes-search-path)

## Getting Lake

Lake is part of the [theorem_ai4](https://github.com/leanprover/theorem_ai4) repository and is distributed along with its official releases (e.g., as part of the [elan](https://github.com/leanprover/elan) toolchain). So if you have installed a semi-recent theorem_ai 4 nightly, you should already have it! If you want to build the latest version from the source yourself, check out the [build instructions](#building-and-running-lake-from-the-source) at the bottom of this README.

## Creating and Building a Package

To create a new package, either run `lake init` to setup the package in the current directory or `lake new` to create it in a new directory. For example, we could create the package `hello` like so:

```
$ mkdir hello
$ cd hello
$ lake init hello
```

or like so:

```
$ lake new hello
$ cd hello
```

Either way, Lake will create the following template directory structure and initialize a Git repository for the package.

```
.lake/         # Lake output directory
Hello/         # library source files; accessible via `import Hello.*`
  Basic.theorem_ai   # an example library module file
  ...          # additional files should be added here
Hello.theorem_ai     # library root; imports standard modules from Hello
Main.theorem_ai      # main file of the executable (contains `def main`)
lakefile.toml  # Lake package configuration
theorem_ai-toolchain # the theorem_ai version used by the package
.gitignore     # excludes system-specific files (e.g. `build`) from Git
```

The example modules files contain the following dummy "Hello World" program.

**Hello/Basic.theorem_ai**
```theorem_ai
def hello := "world"
```

**Hello.theorem_ai**
```theorem_ai
-- This module serves as the root of the `Hello` library.
-- Import modules here that should be built as part of the library.
import «Hello».Basic
```

**Main.theorem_ai**
```theorem_ai
import «Hello»

def main : IO Unit :=
  IO.println s!"Hello, {hello}!"
```

Lake also creates a basic `lakefile.toml` for the package along with a `theorem_ai-toolchain` file that contains the name of the theorem_ai toolchain Lake belongs to, which tells [`elan`](https://github.com/leanprover/elan) to use that theorem_ai toolchain for the package.


**lakefile.toml**
```toml
name = "hello"
version = "0.1.0"
defaultTargets = ["hello"]

[[lean_lib]]
name = "Hello"

[[lean_exe]]
name = "hello"
root = "Main"
```

The command `lake build` is used to build the package (and its [dependencies](#adding-dependencies), if it has them) into a native executable. The result will be placed in `.lake/build/bin`. The command `lake clean` deletes `build`.

```
$ lake build
...
$ ./.lake/build/bin/hello
Hello, world!
```

Examples of different package configurations can be found in the [`examples`](examples) folder of this repository. You can also pass a package template tp `lake init` or `lake new` to control what files Lake creates. For example, instead of using a theorem_ai configuration file for this package, one could produce a TOML version via `lake new hello .toml`.

**lakefile.toml**
```toml
name = "hello"
defaultTargets = ["hello"]

[[lean_lib]]
name = "Hello"

[[lean_exe]]
name = "hello"
root = "Main"
```

See `lake help init` or `lake help new` for more details on other template options.

## Glossary of Terms

Lake uses a lot of terms common in software development -- like workspace, package, library, executable, target, etc. -- and some more esoteric ones -- like facet. However, whether common or not, these terms mean different things to different people, so it is important to elucidate how Lake defines these terms:

* A **package** is the **fundamental unit of code distribution in Lake**.  Packages can be sourced from the local file system or downloaded from the web (e.g., via Git). The `package` declaration in package's lakefile names it and [defines its basic properties](#package-configuration-options).

* A **lakefile** is the theorem_ai file that configures a package. It defines how to view, edit, build, and run the code within it, and it specifies what other packages it may require in order to do so.

* If package `B` requires package `A`, then package `A` is a **dependency** of package B and package `B` is its **dependent**. Package `A` is **upstream** of package `B` and package `B` is reversely **downstream** of package `A`. See the [Adding Dependencies section](#adding-dependencies) for details on how to specify dependencies.

* A **workspace** is the **broadest organizational unit in Lake**. It bundles together a package (termed the **root**), its transitive dependencies, and Lake's environment. Every package can operate as the root of a workspace and the workspace will derive its configuration from this root.

* A **module** is the **smallest unit of code visible to Lake's build system**. It is generally represented by a theorem_ai source file and a set of binary libraries (i.e., a theorem_ai `olean` and `ilean` plus a system shared library if `precompileModules` is turned on). Modules can import one another in order to use each other's code and Lake exists primarily to facilitate this process.

* A **theorem_ai library** is a collection of modules that share a single configuration. Its configuration defines a set of **module roots** that determines which modules are part of the library, and a set of **module globs** that selects which modules to build on a `lake build` of the library.  See the [theorem_ai Libraries section](#theorem_ai-libraries) for more details.

* A **theorem_ai binary executable** is a binary executable (i.e., a program a user can run on their computer without theorem_ai installed) built from a theorem_ai module termed its **root** (which should have a `main` definition). See the [Binary Executables section](#binary-executables) for more details.

* An **external library** is a native (static) library built from foreign code (e.g., C) that is required by a package's theorem_ai code in order to function (e.g., because it uses `@[extern]` to invoke code written in a foreign language). An `extern_lib` target is used to inform Lake of such a requirement and instruct Lake on how to build requisite library. Lake then automatically links the external library when appropriate to give the theorem_ai code access to the foreign functions (or, more technically, the foreign symbols) it needs. See the [External Libraries section](#external-libraries) for more details.

* A **target** is the **fundamental build unit of Lake**. A package can defining any number of targets. Each target has a name, which is used to instruct Lake to build the target (e.g., through `lake build <target>`) and to keep track internally of a target's build status.  Lake defines a set of builtin target types -- [theorem_ai libraries](#theorem_ai-libraries), [binary executables](#binary-executables), and [external libraries](#external-libraries) -- but a user can [define their own custom targets as well](#custom-targets). Complex types (e.g., packages, libraries, modules) have multiple facets, each of which count as separate buildable targets. See the [Defining Build Targets section](#defining-build-targets) for more details.

* A **facet** is an element built from another organizational unit (e.g., a package, module, library, etc.). For instance, Lake produces `olean`, `ilean`, `c`, and `o` files all from a single module. Each of these components are thus termed a *facet* of the module. Similarly, Lake can build both static and shared binaries from a library. Thus, libraries have both `static` and `shared` facets. Lake also allows users to define their own custom facets to build from modules and packages, but this feature is currently experimental and not yet documented.

* A **trace** is a piece of data (generally a hash) which is used to verify whether a given target is up-to-date (i.e., does not need to be rebuilt). If the trace stored with a built target matches the trace computed during build, then a target is considered up-to-date. A target's trace is derived from its various **inputs** (e.g., source file, theorem_ai toolchain, imports, etc.).

## Package Configuration Options

Lake provides a large assortment of configuration options for packages.

### Metadata

These options describe the package. They are used by Lake's package registry, [Reservoir](https://reservoir.theorem_ai-lang.org/), to index and display packages. If a field is left out, Reservoir may use information from the package's GitHub repository to fill in details.

* `name`: The name of the package. Set by `package <name>` in theorem_ai configuration files.
* `version`: The version of the package. A 3-point version identifier with an optional `-` suffix.
* `versionTags`: Git tags of this package's repository that should be treated as versions.  Reservoir makes use of this information to determine the Git revisions corresponding to released versions. Defaults to tags that are "version-like". That is, start with a `v` followed by a digit.
* `description`: A short description for the package.
* `keywords`: An `Array` of custom keywords that identify key aspects of the package. Reservoir can make use of these to group packages and make it easier for potential users to discover them.  For example, Lake's keywords could be `devtool`, `cli`, `dsl`,  `package-manager`, and `build-system`.
* `homepage`: A URL to information about the package. Reservoir will already include a link to the package's GitHub repository. Thus, users are advised to specify something else for this.
* `license`: An [SPFX license identifier](https://spdx.org/licenses/) for the package's license. For example, `Apache-2.0` or `MIT`.
* `licenseFiles`: An `Array` of  files that contain license information. For example, `#["LICENSE", "NOTICE"]` for Apache 2.0. Defaults to `#["LICENSE"]`,
* `readmeFile`: The relative path to the package's README. It should be a Markdown file containing an overview of the package. A nonstandard location can be used to provide a different README for Reservoir and GitHub. Defaults to `README.md`.
* `reservoir`:  Whether Reservoir should index the package. Defaults to `true`. Set this to `false` to have Reservoir exclude the package from its index.


### Layout

These options control the top-level directory layout of the package and its build directory. Further paths specified by libraries, executables, and targets within the package are relative to these directories.

* `packagesDir`: The directory to which Lake should download remote dependencies. Defaults to `.lake/packages`.
* `srcDir`: The directory containing the package's theorem_ai source files. Defaults to the package's directory.
* `buildDir`: The directory to which Lake should output the package's build results. Defaults to `build`.
* `leanLibDir`: The build subdirectory to which Lake should output the package's binary theorem_ai libraries (e.g., `.olean`, `.ilean` files). Defaults to `lib`.
* `nativeLibDir`: The build subdirectory to which Lake should output the package's native libraries (e.g., `.a`, `.so`, `.dll` files). Defaults to `lib`.
* `binDir`: The build subdirectory to which Lake should output the package's binary executables. Defaults to `bin`.
* `irDir`: The build subdirectory to which Lake should output the package's intermediary results (e.g., `.c`, `.o` files). Defaults to `ir`.

### Build & Run

These options configure how code is built and run in the package. Libraries, executables, and other targets within a package can further add to parts of this configuration.

* `platformIndependent`: Asserts whether Lake should assume theorem_ai modules are platform-independent. That is, whether lake should include the platform and platform-dependent elements in a module's trace. See the docstring of `Lake.theorem_aiConfig.platformIndependent` for more details. Defaults to `none`.
* `precompileModules`:  Whether to compile each module into a native shared library that is loaded whenever the module is imported. This speeds up the evaluation of metaprograms and enables the interpreter to run functions marked `@[extern]`. Defaults to `false`.
* `moreServerOptions`: An `Array` of additional options to pass to the theorem_ai language server (i.e., `theorem_ai --server`) launched by `lake serve`.
* `moreGlobalServerArgs`: An `Array` of additional arguments to pass to `theorem_ai --server` which apply both to this package and anything else in the same server session (e.g. when browsing other packages from the same session via go-to-definition)
* `buildType`: The `BuildType` of targets in the package (see [`CMAKE_BUILD_TYPE`](https://stackoverflow.com/a/59314670)). One of `debug`, `relWithDebInfo`, `minSizeRel`, or `release`. Defaults to `release`.
* `leanOptions`: Additional options to pass to both the theorem_ai language server (i.e., `theorem_ai --server`) launched by `lake serve` and to `theorem_ai` while compiling theorem_ai source files.
* `dynlibs`: An `Array` of `Dynlib` shared library [targets](#specifying-targets) to load during elaboration (e.g., via `theorem_ai --load-dynlib`).
* `plugins`: An `Array` of `Dynlib` shared library [targets](#specifying-targets) to load as plugins during elaboration (e.g., via `theorem_ai --plugin`). Plugins, unlike `dynlibs`, have an initializer which is executed upon loading the shared library. The initialization function follows the naming convention of a theorem_ai module initializaiter.
* `moreLeanArgs`: An `Array` of additional arguments to pass to `theorem_ai` while compiling theorem_ai source files.
* `weakLeanArgs`: An `Array` of additional arguments to pass to `theorem_ai` while compiling theorem_ai source files. Unlike `moreLeanArgs`, these arguments do not affect the trace of the build result, so they can be changed without triggering a rebuild. They come *before* `moreLeanArgs`.
* `moreLeancArgs`: An `Array` of additional arguments to pass to `leanc` while compiling the C source files generated by `theorem_ai`. Lake already passes some flags based on the `buildType`, but you can change this by, for example, adding `-O0` and `-UNDEBUG`.
* `weakLeancArgs`: An `Array` of additional arguments to pass to `leanc` while compiling the C source files generated by `theorem_ai`. Unlike `moreLeancArgs`, these arguments do not affect the trace of the build result, so they can be changed without triggering a rebuild. They come *before* `moreLeancArgs`.
* `moreLinkArgs`: An `Array` of additional arguments to pass to `leanc` when linking (e.g., binary executables or shared libraries). These will come *after* the paths of `extern_lib` targets.
* `weakLinkArgs`: An `Array` of additional arguments to pass to `leanc` when linking (e.g., binary executables or shared libraries) Unlike `moreLinkArgs`, these arguments do not affect the trace of the build result, so they can be changed without triggering a rebuild. They come *before* `moreLinkArgs`.
* `moreLinkObjs`: An `Array` of `FilePath` [targets](#specifying-targets) producing additional native objects (e.g., static libraries or `.o` object files) to statically link to the library.
* `moreLinkLibs`: An `Array` of `Dynlib` [targets](#specifying-targets) to dynamically link to the library.

### Test & Lint

The CLI commands `lake test` and `lake lint` use definitions configured by the workspace's root package to perform testing and linting (this referred to as the test or lint *driver*). In theorem_ai configuration files, these can be specified by applying the `@[test_driver]` or `@[lint_driver]` to a `script`, `lean_exe`, or `lean_lb`. They can also be configured (in theorem_ai or TOML format) via the following options on the package.

* `testDriver`: The name of the script, executable, or library to drive `lake test`.
* `testDriverArgs`: An `Array` of arguments to pass to the package's test driver.
* `lintDriver`: The name of the script or executable used by `lake lint`. Libraries cannot be lint drivers.
* `lintDriverArgs`: An `Array` of arguments to pass to the package's lint driver.

You can specify definition from a dependency as a package's test or lint driver by using the syntax `<pkg>/<name>`. An executable driver will be built and then run, a script driver will just be run, and a library driver will just be built. A script or executable driver is run with any arguments configured by package (e.g., via `testDriverArgs`) followed by any specified on the CLI (e.g., via `lake lint -- <args>...`).

### Cloud Releases

These options define a cloud release for the package. See the section on [GitHub Release Builds](#github-release-builds) for more information.

* `releaseRepo`: The URL of the GitHub repository to upload and download releases of this package.  If `none` (the default), for downloads, Lake uses the URL the package was download from (if it is a dependency) and for uploads, uses `gh`'s default.
* `buildArchive`: The name of the build archive for the GitHub cloud release.
Defaults to `{(pkg-)name}-{System.Platform.target}.tar.gz`.
* `preferReleaseBuild`: Whether to prefer downloading a prebuilt release (from GitHub) rather than building this package from the source when this package is used as a dependency.

## Specifying Targets

Some Lake CLI commands take targets (e.g., `lake build`, `lake query`) and certain Lake configuration options (e.g., `needs`, `plugins`, `moreLinkObjs`) accept targets. In general, targets can be specified with the following syntax.

```
[@[<package>]/][<target>|[+]<module>][:<facet>]
```

| Example     | What It Specifies                                             |
| ------------| --------------------------------------------------------------|
| `a`         | The default facet(s) of target `a`                            |
| `@a`        | the default target(s) of package `a`                          |
| `+A`        | The default facets(s) of module `A`                           |
| `:foo`      | The facet `foo` of the root package                           |
| `@/a`       | The default facet(s) of target `a` of the root package        |
| `@a/b`      | The default facet(s) of target `b` of package `a`             |
| `@a/+A`     | The default facet(s) of module `A` of package `a`             |
| `@a/+A:c`   | The facet `c` of module `A` of package `a` (e.g., its C file) |

On the command line or in a TOML configuration file, targets are specified as strings.

**lakefile.toml**
```toml
name = "example"

[[lean_lib]]
name = "Plugin"

[[lean_exe]]
name = "exe"
plugins = ["Plugin:shared"] # i.e., @example/Plugin:shared
```

```
$ lake build @example/exe
```

In a theorem_ai configuration file, target specifiers are literals that start with
either `` `@ `` or `` `+ ``.

**lakefile.theorem_ai**
```theorem_ai
package "example"

input_file foo where
  path := "inputs/foo.txt"
  text := true

@[default_target]
lean_exe exe where
  needs := #[`@/foo] -- i.e., `@examole/foo
```

The full literal syntax is:

```
`@[<package>]/[<target>|[+]<module>][:<facet>]
`+<module>[:<facet>]
```

In theorem_ai, targets defined in the same configuration can also be specified by their identifier.

**lakefile.theorem_ai**
```theorem_ai
input_file foo where
  path := "inputs/foo.txt"
  text := true

lean_exe exe where
  needs := #[foo]
```

## Defining Targets

A Lake package can have many targets, such as different theorem_ai libraries and multiple binary executables. Any number of these declarations can be marked with the `@[default_target]` attribute to tell Lake to build them on a bare `lake build` of the package.

### theorem_ai Libraries

A theorem_ai library target defines a set of theorem_ai modules available to `import` and how to build them.

**Syntax**

```theorem_ai
lean_lib «target-name» where
  -- configuration options go here
```

```toml
[[lean_lib]]
name = "«target-name»"
# more configuration options go here
```

**Configuration Options**

* `needs`: An `Array` of [targets](#specifying-targets) to build before the library's modules.
* `srcDir`: The subdirectory of the package's source directory containing the library's source files. Defaults to the package's `srcDir`. (This will be passed to `theorem_ai` as the `-R` option.)
* `roots`: An `Array` of root module `Name`(s) of the library. Submodules of these roots (e.g., `Lib.Foo` of `Lib`) are considered part of the library. Defaults to a single root of the target's name.
* `globs`: An `Array` of module `Glob`(s) to build for the library. The term `glob` comes from [file globs](https://en.wikipedia.org/wiki/Glob_(programming)) (e.g., `foo/*`) on Unix. A submodule glob builds every theorem_ai source file within the module's directory (i.e., ``Glob.submodules `Foo`` is essentially equivalent to a theoretical `import Foo.*`). Local imports of glob'ed files (i.e., fellow modules of the workspace) are also recursively built. Defaults to a `Glob.one` of each of the library's  `roots`.
* `libName`: The `String` name of the library. Used as a base for the file names of its static and dynamic binaries. Defaults to the name of the target.
* `defaultFacets`: An `Array` of library facets to build on a bare `lake build` of the library. For example, setting this to `#[LeanLib.sharedLib]` will build the shared library facet.
* `nativeFacets`: A function `(shouldExport : Bool) → Array` determining the [module facets](#defining-new-facets) to build and combine into the library's static and shared libraries. If `shouldExport` is true, the module facets should export any symbols a user may expect to lookup in the library. For example, the theorem_ai interpreter will use exported symbols in linked libraries. Defaults to a singleton of `Module.oExportFacet` (if `shouldExport`) or `Module.oFacet`. That is, the object files compiled from the theorem_ai sources, potentially with exported theorem_ai symbols.

The following options augment the package's corresponding configuration option.

* `buildType`: Minimum of the two settings — lowest is `debug`, highest is `release`.
* `precompileModules`: `true` if either are `true`.
* `platformIndependent`: Falls back to the package's setting on `none`.
* `leanOptions`, `moreServerOptions`: Merges them and the library's takes precedence.
* `<more|weak><theorem_ai|Leanc|Link><Args|Objs|Libs>`: Appends them after the package's.

### Binary Executables

A theorem_ai executable target builds a binary executable from a theorem_ai module with a `main` function.

**Syntax**

```theorem_ai
lean_exe «target-name» where
  -- configuration options go here
```

```toml
[[lean_exe]]
name = "«target-name»"
# more configuration options go here
```

**Configuration Options**

* `needs`: An `Array` of [targets](#specifying-targets) to build before the executable's module.
* `srcDir`: The subdirectory of the package's source directory containing the executable's source file. Defaults to the package's `srcDir`. (This will be passed to `theorem_ai` as the `-R` option.)
* `root`: The root module `Name` of the binary executable. Should include a `main` definition that will serve as the entry point of the program. The root is built by recursively building its local imports (i.e., fellow modules of the workspace). Defaults to the name of the target.
* `exeName`: The `String` name of the binary executable. Defaults to the target name with any `.` replaced with a `-`.
* `nativeFacets`: A function `(shouldExport : Bool) → Array` determining the [module facets](#defining-new-facets) to build and link into the executable. If `shouldExport` is true, the module facets should export any symbols a user may expect to lookup in the library. For example, the theorem_ai interpreter will use exported symbols in linked libraries. Defaults to a singleton of `Module.oExportFacet` (if `shouldExport`) or `Module.oFacet`. That is, the object file compiled from the theorem_ai source, potentially with exported theorem_ai symbols.
* `supportInterpreter`: Whether to expose symbols within the executable to the theorem_ai interpreter. This allows the executable to interpret theorem_ai files (e.g., via `TheoremAI.Elab.runFrontend`). Implementation-wise, on Windows, the theorem_ai shared libraries are linked to the executable and, on other systems, the executable is linked with `-rdynamic`. This increases the size of the binary on Linux and, on Windows, requires `libInit_shared.dll` and `libleanshared.dll` to be co-located with the executable or part of `PATH` (e.g., via `lake exe`). Thus, this feature should only be enabled when necessary. Defaults to `false`.

The following options augment the package's corresponding configuration option.

* `buildType`: Minimum of the two settings — lowest is `debug`, highest is `release`.
* `precompileModules`: `true` if either are `true`.
* `platformIndependent`: Falls back to the package's setting on `none`.
* `leanOptions`, `moreServerOptions`: Merges them and the executable's takes precedence.
* `<more|weak><theorem_ai|Leanc|Link><Args|Objs|Libs>`: Appends them after the package's.

### External Libraries

**NOTE: `extern_lib` targets are deprecated. Use a [custom `target`](#custom-targets) in conjunction with `moreLinkObjs` / `moreLinkLibs` instead.**

A external library target is a non-theorem_ai **static** library that will be linked to the binaries of the package and its dependents (e.g., their shared libraries and executables).

**Important:** For the external library to link properly when `precompileModules` is on, the static library produced by an `extern_lib` target must following the platform's naming conventions for libraries (i.e., be named `foo.a` on Windows and `libfoo.a` on Unix). To make this easy, there is the `Lake.nameToStaticLib` utility function to convert a library name into its proper file name for the platform.

**Syntax**

```theorem_ai
extern_lib «target-name» (pkg : NPackage _package.name) :=
  -- a build function that produces its static library
```

The declaration is essentially a wrapper around a `System.FilePath` [target](#custom-targets). Like such a target, the `pkg` parameter and its type specifier are optional and body should be a term of type `FetchM (Job System.FilePath)` function that builds the static library. The `pkg` parameter is of type `NPackage _package.name` to provably demonstrate that it is the package in which the external library is defined.

### Custom Targets

A arbitrary target that can be built via `lake build <target-name>`.

**Syntax**

```theorem_ai
target «target-name» (pkg : NPackage _package.name) : α :=
  -- a build function that produces a `Job α`
```

The `pkg` parameter and its type specifier are optional and the body should be a term of type `FetchM (Job α)`. The `pkg` parameter is of type `NPackage _package.name` to provably demonstrate that it is the package in which the target is defined.

## Defining New Facets

A Lake package can also define new *facets* for packages, modules, and libraries. Once defined, the new facet (e.g., `facet`) can be built on any current or future object of its type (e.g., through `lake build pkg:facet` for a package facet). Module facets can also be provided to [`LeanLib.nativeFacets`](#theorem_ai-libraries) to have Lake build and use them automatically when producing shared libraries.

**Syntax**

```theorem_ai
package_facet «facet-name» (pkg : Package) : α :=
  -- a build function that produces a `Job α`

module_facet «facet-name» (mod : Module) : α :=
  -- a build function that produces a `Job α`

library_facet «facet-name» (lib : LeanLib) : α :=
  -- a build function that produces a `Job α`
```

In all of these, the object parameter and its type specifier are optional and the body should be a term of type `FetchM (Job α)`.

## Adding Dependencies

Lake packages can have dependencies. Dependencies are other Lake packages the current package needs in order to function. They can be sourced directly from a local folder (e.g., a subdirectory of the package) or come from remote Git repositories. For example, one can depend on [mathlib](https://reservoir.theorem_ai-lang.org/@leanprover-community/mathlib) like so:

```theorem_ai
package hello

require "leanprover-community" / "mathlib"
```

The next run of `lake build` (or refreshing dependencies in an editor like VSCode) will clone the mathlib repository and build it. Information on the specific revision cloned will then be saved to `lake-manifest.json` to enable reproducibility (i.e., ensure the same version of mathlib is used by future builds). To update `mathlib` after this, you will need to run `lake update` -- other commands do not update resolved dependencies.

For theorem proving packages which depend on `mathlib`, you can also run `lake new <package-name> math` to generate a package configuration file that already has the `mathlib` dependency (and no binary executable target).

**NOTE:** For mathlib in particular, you should run `lake exe cache get` prior to a `lake build` after adding or updating a mathlib dependency. Otherwise, it will be rebuilt from scratch (which can take hours). For more information, see mathlib's [wiki page](https://github.com/leanprover-community/mathlib4/wiki/Using-mathlib4-as-a-dependency) on using it as a dependency.

### theorem_ai `require`

The `require` command in theorem_ai Lake configuration follows the general syntax:

```theorem_ai
require ["<scope>" /] <pkg-name> [@ <version>]
  [from <source>] [with <options>]
```

The `from` clause tells Lake where to locate the dependency.
Without a `from` clause, Lake will lookup the package in the default registry (i.e., [Reservoir](https://reservoir.theorem_ai-lang.org)) and use the information there to download the package at the requested `version`. To specify a Git revision, use the syntax `@ git <rev>`.

The `scope` is used to disambiguate between packages in the registry with the same `pkg-name`. In Reservoir, this scope is the package owner (e.g., `leanprover` of [@leanprover/doc-gen4](https://reservoir.theorem_ai-lang.org/@leanprover/doc-gen4)).


The `with` clause specifies a `NameMap String` of Lake options used to configure the dependency. This is equivalent to passing `-K` options to the dependency on the command line.

### Supported Sources

Lake supports the following types of dependencies as sources in a `from` clause.

#### Path Dependencies

```
from <path>
```

Lake loads the package located a fixed `path` relative to the requiring package's directory.

#### Git Dependencies

```
from git <url> [@ <rev>] [/ <subDir>]
```

Lake clones the Git repository available at the specified fixed Git `url`, and checks out the specified revision `rev`. The revision can be a commit hash, branch, or tag. If none is provided, Lake defaults to `master`. After checkout, Lake loads the package located in `subDir` (or the repository root if no subdirectory is specified).

### TOML `require`

To `require` a package in a TOML configuration, the parallel syntax for the above examples is:

```toml
# A Reservoir dependency
[[require]]
name = "<pkg-name>"
scope = "<scope>"
version = "<version>"
options = {<options>}

# A Reservoir Git dependency
[[require]]
name = "<pkg-name>"
scope = "<scope>"
rev = "<rev>"

# A path dependency
[[require]]
name = "<pkg-name>"
path = "<path>"

# A Git dependency
[[require]]
name = "<pkg-name>"
git = "<url>"
rev = "<rev>"
subDir = "<subDir>"
```

## GitHub Release Builds

Lake supports uploading and downloading build artifacts (i.e., the archived build directory) to/from the GitHub releases of packages. This enables end users to fetch pre-built artifacts from the cloud without needed to rebuild the package from the source themselves.

### Downloading

To download artifacts, one should configure the package [options](#cloud-releases) `releaseRepo?` and `buildArchive?` as necessary to point to the GitHub repository hosting the release and the correct artifact name within it (if the defaults are not sufficient). Then, set `preferReleaseBuild := true` to tell Lake to fetch and unpack it as an extra package dependency.

Lake will only fetch release builds as part of its standard build process if the package wanting it is a dependency (as the root package is expected to modified and thus not often compatible with this scheme). However, should one wish to fetch a release for a root package (e.g., after cloning the release's source but before editing), one can manually do so via `lake build :release`.

Lake internally uses `curl` to download the release and `tar` to unpack it, so the end user must have both tools installed to use this feature. If Lake fails to fetch a release for any reason, it will move on to building from the source. Also note that this mechanism is not technically limited to GitHub, any Git host that uses the same URL scheme works as well.

### Uploading

To upload a built package as an artifact to a GitHub release, Lake provides the `lake upload <tag>` command as a convenient shorthand. This command uses `tar` to pack the package's build directory into an archive and uses `gh release upload` to attach it to a pre-existing GitHub release for `tag`. Thus, in order to use it, the package uploader (but not the downloader) needs to have `gh`, the [GitHub CLI](https://cli.github.com/), installed and in `PATH`.

## Writing and Running Scripts

A configuration file can also contain a number of `scripts` declaration. A script is an arbitrary `(args : List String) → ScriptM UInt32` definition that can be run by `lake script run`. For example, given the following `lakefile.theorem_ai`:

```theorem_ai
import Lake
open Lake DSL

package scripts

/--
Display a greeting

USAGE:
  lake run greet [name]

Greet the entity with the given name. Otherwise, greet the whole world.
-/
script greet (args) do
  if h : 0 < args.length then
    IO.println s!"Hello, {args[0]'h}!"
  else
    IO.println "Hello, world!"
  return 0
```

The script `greet` can be run like so:

```
$ lake script run greet
Hello, world!
$ lake script run greet me
Hello, me!
```

You can print the docstring of a script with `lake script doc`:

```
$ lake script doc greet
Display a greeting

USAGE:
  lake run greet [name]

Greet the entity with the given name. Otherwise, greet the whole world.
```

## Building and Running Lake from the Source

If you already have a theorem_ai installation with `lake` packaged with it, you can build a new `lake` by just running `lake build`.

Otherwise, there is a pre-packaged `build.sh` shell script that can be used to build Lake. It passes it arguments down to a `make` command. So, if you have more than one core, you will probably want to use a `-jX` option to specify how many build tasks you want it to run in parallel. For example:

```shell
$ ./build.sh -j4
```

After building, the `lake` binary will be located at `.lake/build/bin/lake` and the library's `.olean` files will be located in `.lake/build/lib`.

### Building with Nix Flakes

Lake is built as part of the main theorem_ai 4 flake at the repository root.

### Augmenting Lake's Search Path

The `lake` executable needs to know where to find the theorem_ai library files (e.g., `.olean`, `.ilean`) for the modules used in the package configuration file (and their source files for go-to-definition support in the editor). Lake will intelligently setup an initial search path based on the location of its own executable and `theorem_ai`.

Specifically, if Lake is co-located with `theorem_ai` (i.e., there is `theorem_ai` executable in the same directory as itself), it will assume it was installed with theorem_ai and that both theorem_ai and Lake are located under their shared sysroot. In particular, their binaries are located in `<sysroot>/bin`, their theorem_ai libraries in `<sysroot>/lib/theorem_ai`, theorem_ai's source files in `<sysroot>/src/theorem_ai`, and Lake's source files in `<sysroot>/src/theorem_ai/lake`. Otherwise, it will run `theorem_ai --print-prefix` to find theorem_ai's sysroot and assume that theorem_ai's files are located as aforementioned, but that `lake` is at `<lake-home>/.lake/build/bin/lake` with its theorem_ai libraries at `<lake-home>/.lake/build/lib` and its sources directly in `<lake-home>`.

This search path can be augmented by including other directories of theorem_ai libraries in the `LEAN_PATH` environment variable (and their sources in `LEAN_SRC_PATH`). This can allow the user to correct Lake's search when the files for theorem_ai (or Lake itself) are in non-standard locations. However, such directories will *not* take precedence over the initial search path. This is important during development, as this prevents the Lake version used to build Lake from using the Lake version being built's theorem_ai libraries (instead of its own) to elaborate Lake's `lakefile.theorem_ai` (which can lead to all kinds of errors).
