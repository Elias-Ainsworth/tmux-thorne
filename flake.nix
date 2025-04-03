{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs =
    inputs@{
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      perSystem =
        { pkgs, ... }:
        {
          devShells = {
            default = pkgs.mkShell {
              packages = with pkgs; [
                # Git
                deadnix
                nixfmt-rfc-style
                pre-commit
                statix

                # LSP
                nixd
                shellcheck
              ];
            };
          };
          packages = rec {
            default = tmux-thorne;
            tmux-thorne = pkgs.tmuxPlugins.mkTmuxPlugin {
              pluginName = "thorne";
              version = "0.0.0";
              src = ./tmux;
            };
          };
        };
    };
}
