# Packages elm-pages CLI and elm-tailwind-classes CLI from the project's
# npm package-lock.json so the versions stay in sync with package.json.
#
# The derivation fetches npm deps in the Nix sandbox (--ignore-scripts skips
# elm-tooling and the lamdera binary-download postinstall) and wraps the
# resulting Node.js scripts so the Nix-packaged lamdera is always found first
# on PATH and NODE_PATH points to the bundled node_modules for Vite resolution.
#
# How to update the hash after changing package-lock.json:
#   1. Set hash = pkgs.lib.fakeHash; below
#   2. Run `nix develop` — the build fails with the correct sha256 in "got:"
#   3. Paste that sha256 here
{ pkgs, lamdera }:
let
  # Strip the postinstall script so elm-tooling does not try to download
  # elm/elm-format inside the Nix sandbox (they come from Nix packages).
  patchedSrc = pkgs.runCommand "master-builder-npm-src"
    { nativeBuildInputs = [ pkgs.jq ]; }
    ''
      mkdir $out
      jq 'del(.scripts.postinstall)' ${./package.json} > $out/package.json
      cp ${./package-lock.json} $out/package-lock.json
    '';

  npmDeps = pkgs.fetchNpmDeps {
    name = "master-builder-npm-deps";
    src = patchedSrc;
    # Computed by building with pkgs.lib.fakeHash and reading the "got:" line.
    # To update: set back to pkgs.lib.fakeHash, run `devenv shell`, replace with
    # the sha256 printed in the error output.
    hash = "sha256-jDHMrlU2iWIeM+qLqwvb8VooVomKSlrCZBGaIVETwvE=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "master-builder-npm-tools";
  version = "3.1.5";

  src = patchedSrc;
  inherit npmDeps;

  nativeBuildInputs = [
    pkgs.nodejs_22
    pkgs.npmHooks.npmConfigHook
    pkgs.makeWrapper
  ];

  # npmConfigHook uses $npmDeps (read-only Nix store) as the npm cache for
  # fetcherVersion 1. npm tries to write to _cacache/tmp inside it → EACCES.
  # makeCacheWritable copies npmDeps to a writable tmpdir before npm ci.
  makeCacheWritable = "1";

  # npm rebuild (run by npmConfigHook after npm ci) does NOT have --ignore-scripts
  # by default. lamdera's postinstall calls elm-tooling install, which tries to
  # download binaries from the network and fails in the Nix sandbox.
  npmRebuildFlags = "--ignore-scripts";

  # elm-tailwind-classes is a git dependency (git+ssh://github.com/...).
  # npm always runs prepare/postinstall for git deps during npm ci (even with
  # --ignore-scripts), and elm-tailwind-classes' postinstall calls elm-tooling
  # install which tries to download Elm binaries from the internet.
  # postPatch runs just before postPatchHooks (which contains npmConfigHook),
  # so we can stub elm-tooling with a no-op before npm ci executes.
  postPatch = ''
    mkdir -p "$TMPDIR/fake-bin"
    printf '#!/bin/sh\nexec true\n' > "$TMPDIR/fake-bin/elm-tooling"
    chmod +x "$TMPDIR/fake-bin/elm-tooling"
    export PATH="$TMPDIR/fake-bin:$PATH"
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib
    cp -r node_modules $out/lib/

    # Patch broken tailwind-resolver default export (upstream bug in 0.3.x):
    # The minified bundle exports 'u1' which doesn't exist in the module.
    for f in \
      $out/lib/node_modules/tailwind-resolver/dist/index.mjs \
      $out/lib/node_modules/elm-tailwind-classes/node_modules/tailwind-resolver/dist/index.mjs; do
      if [ -f "$f" ]; then
        substituteInPlace "$f" --replace-quiet "u1 as default" "h1 as default"
      fi
    done

    # elm-pages CLI
    # Entry point: node_modules/elm-pages/generator/src/cli.js
    makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/elm-pages \
      --add-flags "$out/lib/node_modules/elm-pages/generator/src/cli.js" \
      --prefix PATH : "$out/lib/node_modules/.bin" \
      --prefix PATH : "${lamdera}/bin" \
      --set NODE_PATH "$out/lib/node_modules"

    # elm-tailwind-classes CLI  (elm-tailwind-classes gen)
    # Entry point: node_modules/elm-tailwind-classes/vite-plugin/cli.js
    # Verify with: cat node_modules/elm-tailwind-classes/package.json | jq .bin
    # If wrong, adjust the path to match the actual "bin" field in package.json.
    makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/elm-tailwind-classes \
      --add-flags "$out/lib/node_modules/elm-tailwind-classes/vite-plugin/cli.js" \
      --prefix PATH : "$out/lib/node_modules/.bin" \
      --set NODE_PATH "$out/lib/node_modules"

    runHook postInstall
  '';
}
