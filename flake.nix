{
  description = "Nix flake for the Playwright CLI";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = nixpkgs.legacyPackages.${system};
            inherit system;
          }
        );
    in
    {
      packages = forAllSystems ({ pkgs, ... }: {
        default = pkgs.runCommand "playwright-cli" {} "mkdir $out";
      });

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixfmt);
    };
}
