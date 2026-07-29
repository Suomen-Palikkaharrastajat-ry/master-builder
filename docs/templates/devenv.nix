# Starter devenv.nix for a family app repo (Haskell statics generator + Elm SPA).
#
# Two profiles:
#   shell — interactive development (devenv.yaml sets this as the default)
#   ci    — GitHub Actions; puts the Nix-built generator binary on PATH so
#           `make dist-ci` never has to compile Haskell
#
# `make vendor` must run before `devenv shell` so vendor/master-builder exists.
#
# Note the profile wiring at the bottom: devenv (v2.1.2) expects
# `profiles.<name>.module`, not `profiles.<name>`.
let
  mkTools = pkgs: pkgs.callPackage ./pkgs/npm-tools.nix { }; # wraps mk-npm-tools.nix

  # Haskell package set: the shared statics-common package from master-builder,
  # composed with this repo's local overrides. See overrides.nix.
  #
  # Keep the `ci` profile free of ./overlays.nix — an overlay re-instantiates the
  # whole package set, so every derivation hash changes and CI can no longer pull
  # from the shared cachix cache. Overlays are a dev-shell concern.
  hpkgsFor =
    pkgs:
    pkgs.haskell.packages.ghc96.override {
      overrides = import ./overrides.nix { inherit pkgs; };
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

      # elm-review and elm-json are required because CI runs `make check`.
      packages = [
        pkgs.cabal-install
        staticsPackage
        npmTools
        pkgs.nodejs_22
        hpkgs.hlint
        hpkgs.fourmolu
        pkgs.elmPackages.elm-review
        pkgs.elmPackages.elm-json
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
      # overlays = [ (import ./overlays.nix) ];  # dev-shell package pins, if any

      languages.elm.enable = true;
      languages.haskell.enable = true;
      languages.haskell.package = pkgs.haskell.packages.ghc96.ghc;

      # dotenv.enable = true;  # enable for repos that ship a .env

      env.NODE_PATH = "${npmTools}/lib/node_modules";

      packages = with pkgs; [
        cabal-install
        npmTools
        nodejs_22
        entr
        git
        treefmt
        haskell.packages.ghc96.hlint
        haskell.packages.ghc96.fourmolu
        elmPackages.elm-review
        elmPackages.elm-json
        # elm-format is provided by languages.elm.enable
      ];

      enterShell = ''
        ln -sfn "${npmTools}/lib/node_modules" node_modules
        ln -sfn "${npmTools}/lib/node_modules" elm-app/node_modules
      '';
    };
in
{
  profiles.shell.module = {
    imports = [ shell ];
  };

  profiles.ci.module = {
    imports = [ ci ];
  };
}
