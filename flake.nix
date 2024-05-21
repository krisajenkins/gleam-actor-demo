{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/a0906f14161a5c5792e9883117b9471f5bf6df72";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ];
        };
      in
      {
        devShell =
          with pkgs;
          with pkgs.darwin.apple_sdk.frameworks;
          mkShell {
            buildInputs = [
              erlang
              erlang-ls
              erlfmt
              rebar3
              gleam

              # DX
              tree-sitter
              flyctl
              (pkgs.writeShellScriptBin "observer" ''
                # See https://gist.github.com/pnc/9e957e17d4f9c6c81294
                erl -sname observer -setcookie MyCookie -run observer
              '')
            ];
          };
      });
}
