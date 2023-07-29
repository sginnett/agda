{
  description = "Agda is a dependently typed programming language / interactive theorem prover.";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }: (flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; overlays = [ self.overlay ]; };
  in {
    packages = {
      inherit (pkgs.haskellPackages) Agda;

      # TODO agda2-mode
    };

    defaultPackage = self.packages.${system}.Agda;

    devShell = pkgs.haskellPackages.shellFor {
      packages = ps: with ps; [ Agda ];
      nativeBuildInputs = with pkgs; [
        cabal-install
        haskell-language-server
        haskellPackages.fix-whitespace

        # documentation
        (python3.withPackages (ps: with ps; [
          sphinx
          sphinx_rtd_theme
        ]))
      ];
    };
  })) // {
    overlay = final: prev: {
      haskellPackages = prev.haskellPackages.override {
        overrides = self.haskellOverlay;
      };
    };

    haskellOverlay = final: prev: let
      inherit (final) callCabal2nixWithOptions;

      shortRev = builtins.substring 0 9 self.rev;

      postfix = if self ? revCount then "${toString self.revCount}_${shortRev}" else "Dirty";
    in {
      # TODO use separate evaluation system?
      Agda = callCabal2nixWithOptions "Agda" ./. "--flag enable-cluster-counting" ({
        mkDerivation = args: final.mkDerivation (args // {
          version = "${args.version}-pre${postfix}";

          postInstall = "$out/bin/agda-mode compile";

          # TODO Make check phase work
          # At least requires:
          #   Setting AGDA_BIN (or using the Makefile, which at least requires cabal-install)
          #   Making agda-stdlib available (or disabling the relevant tests somehow)
          doCheck = false;
        });
      });
    };
  };
}
