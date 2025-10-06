{
  inputs.TheoremAI.url = "../..";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.temci.url = "github:Kha/temci";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.disable-st.url = "https://github.com/Kha/theorem_ai4/commit/no-st.patch";
  inputs.disable-st.flake = false;

  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (system: { packages = rec {
    leanPkgs = inputs.TheoremAI.packages.${system};
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    ocamlPkgs = pkgs.ocaml-ng.ocamlPackages;
    # for binarytrees.hs
    ghcPackages = p: [ p.parallel ];
    ghc = pkgs.haskell.packages.ghc98.ghcWithPackages ghcPackages; #.override { withLLVM = true; };
    ocaml = ocamlPkgs.ocaml;
    # note that this will need to be compiled from source
    ocamlFlambda = ocaml.override { flambdaSupport = true; };
    mlton = pkgs.mltonHEAD;
    mlkit = pkgs.mlkit;
    swift = pkgs.swift;
    temci = inputs.temci.packages.${system}.default.override { doCheck = false; };

    default = pkgs.stdenv.mkDerivation rec {
      name = "bench";
      src = ./.;
      # we're not usually building theorem_ai with Nix anymore
      #LEAN_BIN = "${leanPkgs.theorem_ai-all}/bin";
      #LEAN_GCC_BIN = "${theorem_ai { stdenv = pkgs.gcc9Stdenv; }}/bin";
      GHC = "${ghc}/bin/ghc";
      OCAML = "${ocaml}/bin/ocamlopt.opt";
      #OCAML_FLAMBDA = "${ocamlFlambda}/bin/ocamlopt.opt";
      MLTON_BIN = "${mlton}/bin";
      MLKIT = "${mlkit}/bin/mlkit";
      SWIFTC = "${swift}/bin/swiftc";
      TEMCI = "${temci}/bin/temci";
      buildInputs = with pkgs; [
        ((builtins.elemAt temci.nativeBuildInputs 0).withPackages (ps: [ temci ps.numpy ps.pyyaml ]))
        ocaml
        ocamlPkgs.findlib
        ocamlPkgs.domainslib
        temci
        pkgs.linuxPackages.perf time unixtools.column
      ];
      patchPhase = ''
        patchShebangs .
      '';
      makeFlags = [ "report_cross.csv" ];
      installPhase = ''
        mkdir $out
        cp -r report *.csv $out
      '';
    };

    theorem_ai-variants = pkgs.stdenv.mkDerivation rec {
      name = "lean_bench";
      src = ./.;
      LEAN_BIN = "${leanPkgs.theorem_ai-all}/bin";
      LEAN_NO_REUSE_BIN = "${(leanPkgs.override (args: {
        src = pkgs.runCommand "theorem_ai-no-reuse-src" {} ''
          cp -r ${args.src} $out
          substituteInPlace $out/src/theorem_ai/Compiler/IR.theorem_ai --replace "decls.map Decl.insertResetReuse" "decls"
        '';
      })).stage2.theorem_ai-all}/bin";
      LEAN_NO_BORROW_BIN = "${(leanPkgs.override (args: {
        src = pkgs.runCommand "theorem_ai-no-borrow-src" {} ''
          cp -r ${args.src} $out
          substituteInPlace $out/src/theorem_ai/Compiler/IR.theorem_ai --replace "inferBorrow" "pure"
        '';
      })).stage2.theorem_ai-all}/bin";
      LEAN_NO_ST_BIN = "${(leanPkgs.override (args: {
        src = pkgs.runCommand "theorem_ai-no-st-src" {} ''
          cp -r ${args.src} $out
          chmod -R u+w $out
          cd $out
          patch -p1 < ${inputs.disable-st}
        '';
      })).theorem_ai-all}/bin";
      PARSER_TEST_FILE = ../../src/Init/Prelude.theorem_ai;
      buildInputs = with pkgs; [
        ((builtins.elemAt temci.nativeBuildInputs 0).withPackages (ps: [ temci ps.numpy ps.pyyaml ]))
        temci
        pkgs.linuxPackages.perf time unixtools.column
      ];
      patchPhase = ''
        patchShebangs .
      '';
      makeFlags = [ "report_TheoremAI.csv" ];
      installPhase = ''
        mkdir $out
        cp -r report *.csv $out
      '';
    };
  };});
}
