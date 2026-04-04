let shell = { pkgs, ...}:
  let
    lamdera  = pkgs.elmPackages.lamdera;
    npmTools = pkgs.callPackage ./pkgs/npm-tools.nix { inherit lamdera; };
  in
  {
    # https://devenv.sh/languages/
    languages = {
      elm.enable = true;
    };

    # https://devenv.sh/packages/
    packages = [
      pkgs.elmPackages.elm-format
      pkgs.elmPackages.elm-review
      pkgs.elmPackages.elm-test
      pkgs.elmPackages.elm-json
      lamdera
      pkgs.nodejs_22
      npmTools          # provides elm-pages and elm-tailwind-classes bins
      pkgs.treefmt
    ];

    dotenv.disableHint = true;

    # Vite (and elm-pages dev server) must be able to `require()` packages
    # like @tailwindcss/vite and elm-tailwind-classes/vite at runtime.
    # npmTools bundles the full node_modules tree; expose it via NODE_PATH.
    env.NODE_PATH = "${npmTools}/lib/node_modules";

    enterShell = ''
      # ESM `import` does not respect NODE_PATH; only CJS `require()` does.
      # elm-pages.config.mjs uses `import` for @tailwindcss/vite and
      # elm-tailwind-classes/vite, so we symlink node_modules → the Nix store
      # tree so Node's standard module resolution finds them.
      ln -sfn "${npmTools}/lib/node_modules" node_modules

      echo ""
      echo "── master-builder dev environment ────────────────────"
      echo "  Elm:       $(elm --version)"
      echo "  Node:      $(node --version)"
      echo "  lamdera:   $(lamdera --version 2>/dev/null || echo ok)"
      echo "  elm-pages: $(elm-pages --version)"
      echo ""
      echo "  make dev   — start dev server (uses template/)"
      echo "  make watch — start dev server (uses content/)"
      echo "  make build — production build"
      echo ""
    '';
  };

in {
  profiles.shell.module = {
    imports = [ shell ];
  };
}
