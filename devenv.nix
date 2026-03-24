let shell = { pkgs, ...}: {
  # https://devenv.sh/languages/
  languages = {
    elm.enable = true;
  };

  # https://devenv.sh/packages/
  packages = [
    pkgs.nodejs
    pkgs.elmPackages.elm-format
    pkgs.elmPackages.elm-review
    pkgs.elmPackages.elm-test
    pkgs.elmPackages.elm-json
    pkgs.treefmt
  ];

  dotenv.enable = true;

  # elm-pages is typically run via npx or installed via npm.
  # We can create a script to make it easier to run.
  scripts.elm-pages.exec = "npx elm-pages \"$@\"";

  enterShell = ''
    echo ""
    echo "── pages dev environment ────────────────────────────"
    echo "  Elm:       $(elm --version)"
    echo "  Node:      $(node --version)"
    echo "  elm-pages: $(npx elm-pages --version 2>/dev/null || echo 'run npm install first')"
    echo ""
    echo "  make dev   — start dev server (uses template/)"
    echo "  make watch — start dev server (uses content/)"
    echo ""
  '';
};

in {
  profiles.shell.module = {
    imports = [ shell ];
  };
}
