{
  description = "elm-pages + elm-tailwind-classes dev shell (standalone)";

  inputs.nixpkgs.url =
    "github:nixos/nixpkgs/719d25d6d269c87936932bc6db8d8da2b9278c85";

  outputs = { self, nixpkgs }:
    let
      system  = "x86_64-linux";
      pkgs    = import nixpkgs { inherit system; };
      lamdera = pkgs.elmPackages.lamdera;
      npmTools = pkgs.callPackage ./nix/npm-tools.nix { inherit lamdera; };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.elmPackages.elm
          pkgs.elmPackages.elm-format
          pkgs.elmPackages.elm-review
          pkgs.elmPackages.elm-test
          pkgs.elmPackages.elm-json
          lamdera
          pkgs.nodejs_22
          npmTools          # provides elm-pages and elm-tailwind-classes bins
        ];

        shellHook = ''
          # Belt-and-suspenders: ensure Vite can find elm-tailwind-classes/vite
          # and @tailwindcss/vite when resolving imports in elm-pages.config.mjs
          export NODE_PATH="${npmTools}/lib/node_modules:''${NODE_PATH:-}"

          echo ""
          echo "── master-builder nix dev shell ──────────────────────────"
          echo "  elm:                  $(elm --version)"
          echo "  lamdera:              $(lamdera --version 2>/dev/null || echo ok)"
          echo "  elm-pages:            $(elm-pages --version)"
          echo ""
          echo "  make dev   — start dev server"
          echo "  make build — build site"
          echo ""
        '';
      };
    };
}
