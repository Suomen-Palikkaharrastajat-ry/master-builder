# Starter devenv.nix for a family app repo (Haskell statics generator + Elm SPA).
# Two profiles: `shell` (interactive dev) and `ci` (builds the statics package via
# callCabal2nix). npm tools come from the shared builder in master-builder.
#
# `make vendor` must run before `devenv shell` so vendor/master-builder exists.
let
  mkTools =
    pkgs:
    pkgs.callPackage ./pkgs/npm-tools.nix { }; # thin wrapper over mk-npm-tools.nix

  # Shared Haskell package from master-builder, plus any repo-local overrides.
  hpkgsFor =
    pkgs:
    pkgs.haskell.packages.ghc96.override {
      overrides = hself: hsuper: {
        statics-common =
          hself.callCabal2nix "statics-common"
            ./vendor/master-builder/packages-hs/statics-common
            { };
        # Add repo-local Haskell overrides here (see overrides.nix if present).
      };
    };

  ci =
    { pkgs, ... }:
    let
      npmTools = mkTools pkgs;
      hpkgs = hpkgsFor pkgs;
      staticsPackage = hpkgs.callCabal2nix "statics" ./statics { };
    in
    {
      languages.elm.enable = true;
      languages.haskell.enable = true;
      languages.haskell.package = pkgs.haskell.packages.ghc96.ghc;

      env.NODE_PATH = "${npmTools}/lib/node_modules";

      packages = [
        pkgs.cabal-install
        staticsPackage
        npmTools
        pkgs.nodejs_22
        hpkgs.hlint
        hpkgs.fourmolu
      ];

      enterShell = ''
        ln -sfn "${npmTools}/lib/node_modules" node_modules
        ln -sfn "${npmTools}/lib/node_modules" elm-app/node_modules
      '';
    };

  shell =
    { pkgs, ... }:
    let
      npmTools = mkTools pkgs;
    in
    {
      languages.elm.enable = true;
      languages.haskell.enable = true;
      languages.haskell.package = pkgs.haskell.packages.ghc96.ghc;

      env.NODE_PATH = "${npmTools}/lib/node_modules";

      packages = [
        pkgs.cabal-install
        npmTools
        pkgs.nodejs_22
        pkgs.haskell.packages.ghc96.hlint
        pkgs.haskell.packages.ghc96.fourmolu
        pkgs.elmPackages.elm-format
        pkgs.elmPackages.elm-review
        pkgs.elmPackages.elm-json
        pkgs.treefmt
      ];

      enterShell = ''
        ln -sfn "${npmTools}/lib/node_modules" node_modules
        ln -sfn "${npmTools}/lib/node_modules" elm-app/node_modules
      '';
    };
in
{
  imports = [ shell ];
  profiles.shell = shell;
  profiles.ci = ci;
}
