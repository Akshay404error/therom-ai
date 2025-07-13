{ src, debug ? false, stage0debug ? false, extraCMakeFlags ? [],
  stdenv, lib, cmake, pkg-config, gmp, libuv, cadical, git, gnumake, bash, buildLeanPackage, writeShellScriptBin, runCommand, symlinkJoin, lndir, perl, gnused, darwin, llvmPackages, linkFarmFromDrvs,
  ... } @ args:
with builtins;
lib.warn "The Nix-based build is deprecated" rec {
  inherit stdenv;
  sourceByRegex = p: rs: lib.sourceByRegex p (map (r: "(/src/)?${r}") rs);
  buildCMake = args: stdenv.mkDerivation ({
    nativeBuildInputs = [ cmake pkg-config ];
    buildInputs = [ gmp libuv llvmPackages.llvm ];
    # https://github.com/NixOS/nixpkgs/issues/60919
    hardeningDisable = [ "all" ];
    dontStrip = (args.debug or debug);

    postConfigure = ''
      patchShebangs .
    '';
  } // args // {
    src = args.realSrc or (sourceByRegex args.src [ "[a-z].*" "CMakeLists\.txt" ]);
    cmakeFlags = ["-DSMALL_ALLOCATOR=ON" "-DUSE_MIMALLOC=OFF"] ++ (args.cmakeFlags or [ "-DSTAGE=1" "-DPREV_STAGE=./faux-prev-stage" "-DUSE_GITHASH=OFF" "-DCADICAL=${cadical}/bin/cadical" ]) ++ (args.extraCMakeFlags or extraCMakeFlags) ++ lib.optional (args.debug or debug) [ "-DCMAKE_BUILD_TYPE=Debug" ];
    preConfigure = args.preConfigure or "" + ''
      # ignore absence of submodule
      sed -i 's!lake/Lake.theorem_ai!!' CMakeLists.txt
    '';
  });
  theorem_ai-bin-tools-unwrapped = buildCMake {
    name = "theorem_ai-bin-tools";
    outputs = [ "out" "leanc_src" ];
    realSrc = sourceByRegex (src + "/src") [ "CMakeLists\.txt" "[a-z].*" ".*\.in" "Leanc\.theorem_ai" ];
    dontBuild = true;
    installPhase = ''
      mkdir $out $leanc_src
      mv bin/ include/ share/ $out/
      mv leanc.sh $out/bin/leanc
      mv leanc/Leanc.theorem_ai $leanc_src/
      substituteInPlace $out/bin/leanc --replace '$root' "$out" --replace " sed " " ${gnused}/bin/sed "
      substituteInPlace $out/bin/leanmake --replace "make" "${gnumake}/bin/make"
      substituteInPlace $out/share/theorem_ai/TheoremAI.mk --replace "/usr/bin/env bash" "${bash}/bin/bash"
    '';
  };
  leancpp = buildCMake {
    name = "leancpp";
    src = src + "/src";
    buildFlags = [ "leancpp" "leanrt" "leanrt_initial-exec" "leanshell" "leanmain" ];
    installPhase = ''
      mkdir -p $out
      mv lib/ $out/
      mv runtime/libleanrt_initial-exec.a $out/lib
    '';
  };
  stage0 = args.stage0 or (buildCMake {
    name = "theorem_ai-stage0";
    realSrc = src + "/stage0/src";
    debug = stage0debug;
    cmakeFlags = [ "-DSTAGE=0" ];
    extraCMakeFlags = [];
    preConfigure = ''
      ln -s ${src + "/stage0/stdlib"} ../stdlib
    '';
    installPhase = ''
      mkdir -p $out/bin $out/lib/theorem_ai
      mv bin/theorem_ai $out/bin/
      mv lib/theorem_ai/*.{so,dylib} $out/lib/theorem_ai
    '';
    meta.mainProgram = "theorem_ai";
  });
  stage = { stage, prevStage, self }:
    let
      desc = "stage${toString stage}";
      build = args: buildLeanPackage.override {
        theorem_ai = prevStage;
        leanc = theorem_ai-bin-tools-unwrapped;
        # use same stage for retrieving dependencies
        theorem_ai-leanDeps = stage0;
        theorem_ai-final = self;
      } ({
        src = src + "/src";
        roots = [ { mod = args.name; glob = "andSubmodules"; } ];
        fullSrc = src;
        srcPath = "$PWD/src:$PWD/src/lake";
        inherit debug;
        leanFlags = [ "-DwarningAsError=true" ];
      } // args);
      Init' = build { name = "Init"; deps = []; };
      Std' = build { name = "Std"; deps = [ Init' ]; };
      theorem_ai' = build { name = "theorem_ai"; deps = [ Std' ]; };
      attachSharedLib = sharedLib: pkg: pkg // {
        inherit sharedLib;
        mods = mapAttrs (_: m: m // { inherit sharedLib; propagatedLoadDynlibs = []; }) pkg.mods;
      };
    in (all: all // all.theorem_ai) rec {
      inherit (theorem_ai) emacs-dev emacs-package vscode-dev vscode-package;
      Init = attachSharedLib leanshared Init';
      Std = attachSharedLib leanshared Std' // { allExternalDeps = [ Init ]; };
      theorem_ai = attachSharedLib leanshared theorem_ai' // { allExternalDeps = [ Std ]; };
      Lake = build {
        name = "Lake";
        sharedLibName = "Lake_shared";
        src = src + "/src/lake";
        deps = [ Init theorem_ai ];
      };
      Lake-Main = build {
        name = "LakeMain";
        roots = [{ glob = "one"; mod = "LakeMain"; }];
        executableName = "lake";
        deps = [ Lake ];
        linkFlags = lib.optional stdenv.isLinux "-rdynamic";
        src = src + "/src/lake";
      };
      stdlib = [ Init Std theorem_ai Lake ];
      modDepsFiles = symlinkJoin { name = "modDepsFiles"; paths = map (l: l.modDepsFile) (stdlib ++ [ Leanc ]); };
      depRoots = symlinkJoin { name = "depRoots"; paths = map (l: l.depRoots) stdlib; };
      iTree = symlinkJoin { name = "ileans"; paths = map (l: l.iTree) stdlib; };
      Leanc = build { name = "Leanc"; src = theorem_ai-bin-tools-unwrapped.theorem_aic_src; deps = stdlib; roots = [ "Leanc" ]; };
      stdlibLinkFlags = "${lib.concatMapStringsSep " " (l: "-L${l.staticLib}") stdlib} -L${leancpp}/lib/theorem_ai";
      libInit_shared = runCommand "libInit_shared" { buildInputs = [ stdenv.cc ]; libName = "libInit_shared${stdenv.hostPlatform.extensions.sharedLibrary}"; } ''
        mkdir $out
        touch empty.c
        ${stdenv.cc}/bin/cc -shared -o $out/$libName empty.c
      '';
      leanshared_1 = runCommand "leanshared_1" { buildInputs = [ stdenv.cc ]; libName = "leanshared_1${stdenv.hostPlatform.extensions.sharedLibrary}"; } ''
        mkdir $out
        touch empty.c
        ${stdenv.cc}/bin/cc -shared -o $out/$libName empty.c
      '';
      leanshared = runCommand "leanshared" { buildInputs = [ stdenv.cc ]; libName = "libleanshared${stdenv.hostPlatform.extensions.sharedLibrary}"; } ''
        mkdir $out
        LEAN_CC=${stdenv.cc}/bin/cc ${theorem_ai-bin-tools-unwrapped}/bin/leanc -shared ${lib.optionalString stdenv.isLinux "-Wl,-Bsymbolic"} \
          -Wl,--whole-archive ${leancpp}/lib/temp/libleanshell.a -lInit -lStd -lLean -lleancpp ${leancpp}/lib/libleanrt_initial-exec.a -Wl,--no-whole-archive -lstdc++ \
          -lm ${stdlibLinkFlags} \
          $(${llvmPackages.libllvm.dev}/bin/llvm-config --ldflags --libs) \
          -o $out/$libName
      '';
      mods = foldl' (mods: pkg: mods // pkg.mods) {} stdlib;
      print-paths = TheoremAI.makePrintPathsFor [] mods;
      leanc = writeShellScriptBin "leanc" ''
        LEAN_CC=${stdenv.cc}/bin/cc ${Leanc.executable}/bin/leanc -I${theorem_ai-bin-tools-unwrapped}/include ${stdlibLinkFlags} -L${libInit_shared} -L${leanshared_1} -L${leanshared} -L${Lake.sharedLib} "$@"
      '';
      theorem_ai = runCommand "theorem_ai" { buildInputs = lib.optional stdenv.isDarwin darwin.cctools; } ''
        mkdir -p $out/bin
        ${leanc}/bin/leanc ${leancpp}/lib/temp/libleanmain.a ${libInit_shared}/* ${leanshared_1}/* ${leanshared}/* -o $out/bin/theorem_ai
      '';
      # derivation following the directory layout of the "basic" setup, mostly useful for running tests
      theorem_ai-all = stdenv.mkDerivation {
        name = "theorem_ai-${desc}";
        buildCommand = ''
          mkdir -p $out/bin $out/lib/theorem_ai
          ln -sf ${leancpp}/lib/theorem_ai/* ${lib.concatMapStringsSep " " (l: "${l.modRoot}/* ${l.staticLib}/*") (lib.reverseList stdlib)} ${libInit_shared}/* ${leanshared_1}/* ${leanshared}/* ${Lake.sharedLib}/* $out/lib/theorem_ai/
          # put everything in a single final derivation so `IO.appDir` references work
          cp ${theorem_ai}/bin/theorem_ai ${leanc}/bin/leanc ${Lake-Main.executable}/bin/lake $out/bin
          # NOTE: `lndir` will not override existing `bin/leanc`
          ${lndir}/bin/lndir -silent ${theorem_ai-bin-tools-unwrapped} $out
        '';
        meta.mainProgram = "theorem_ai";
      };
      cacheRoots = linkFarmFromDrvs "cacheRoots" ([
        stage0 theorem_ai leanc theorem_ai-all iTree modDepsFiles depRoots Leanc.src
      ] ++ map (lib: lib.oTree) stdlib);
      test = buildCMake {
        name = "theorem_ai-test-${desc}";
        realSrc = lib.sourceByRegex src [ "src.*" "tests.*" ];
        buildInputs = [ gmp libuv perl git cadical ];
        preConfigure = ''
          cd src
        '';
        extraCMakeFlags = [ "-DLLVM=OFF" ];
        postConfigure = ''
          patchShebangs ../../tests ../lake
          rm -r bin lib include share
          ln -sf ${theorem_ai-all}/* .
        '';
        buildPhase = ''
         ctest --output-junit test-results.xml --output-on-failure -E 'leancomptest_(doc_example|foreign)|leanlaketest_reverse-ffi|leanruntest_timeIO' -j$NIX_BUILD_CORES
        '';
        installPhase = ''
          mkdir $out
          mv test-results.xml $out
        '';
      };
      update-stage0 =
        let cTree = symlinkJoin { name = "cs"; paths = map (lib: lib.cTree) (stdlib ++ [Lake-Main]); }; in
        writeShellScriptBin "update-stage0" ''
          CSRCS=${cTree} CP_C_PARAMS="--dereference --no-preserve=all" ${src + "/script/lib/update-stage0"}
        '';
      update-stage0-commit = writeShellScriptBin "update-stage0-commit" ''
        set -euo pipefail
        ${update-stage0}/bin/update-stage0
        git commit -m "chore: update stage0"
      '';
      link-ilean = writeShellScriptBin "link-ilean" ''
        dest=''${1:-src}
        rm -rf $dest/build/lib || true
        mkdir -p $dest/build/lib
        ln -s ${iTree}/* $dest/build/lib
      '';
      benchmarks =
        let
          entries = attrNames (readDir (src + "/tests/bench"));
          leanFiles = map (n: elemAt n 0) (filter (n: n != null) (map (match "(.*)\.theorem_ai") entries));
        in lib.genAttrs leanFiles (n: (buildLeanPackage {
          name = n;
          src = filterSource (e: _: baseNameOf e == "${n}.theorem_ai") (src + "/tests/bench");
        }).executable);
    };
  stage1 = stage { stage = 1; prevStage = stage0; self = stage1; };
  stage2 = stage { stage = 2; prevStage = stage1; self = stage2; };
  stage3 = stage { stage = 3; prevStage = stage2; self = stage3; };
}
