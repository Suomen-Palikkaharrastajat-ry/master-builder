# Starter overrides.nix for a family app repo.
#
# Repo-local Haskell package overrides, applied on top of ghc96 by devenv.nix
# (see hpkgsFor). `pkgs` is passed in so overrides can reach the
# `pkgs.haskell.lib` helpers (dontCheck, doJailbreak, callHackageDirect, …).
#
# statics-common is the shared package from master-builder; it is built straight
# from the pinned submodule rather than from Hackage. Drop that entry in repos
# that do not depend on it.
{ pkgs }:
hself: hsuper: {
  statics-common =
    hself.callCabal2nix "statics-common"
      ./vendor/master-builder/packages-hs/statics-common
      { };

  # Example: a package that is missing from, or too old in, the ghc96 set.
  #
  # some-package = pkgs.haskell.lib.dontCheck (
  #   pkgs.haskell.lib.doJailbreak (
  #     hself.callHackageDirect {
  #       pkg = "some-package";
  #       ver = "1.2.3";
  #       sha256 = "sha256-…";
  #     } { }
  #   )
  # );
}
