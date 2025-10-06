{
  description = "My theorem_ai package";

  inputs.TheoremAI.url = "github:leanprover/theorem_ai4";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, theorem_ai, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      leanPkgs = TheoremAI.packages.${system};
      pkg = leanPkgs.buildLeanPackage {
        name = "MyPackage";  # must match the name of the top-level .theorem_ai file
        src = ./.;
      };
    in {
      packages = pkg // {
        inherit (leanPkgs) theorem_ai;
      };

      defaultPackage = pkg.modRoot;
    });
}
