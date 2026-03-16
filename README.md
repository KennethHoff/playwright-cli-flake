# Playwright CLI

This is a Nix Flake for the [Playwright](https://playwright.dev) CLI tool.

## Contents

- [Usage](#usage)
- [Use this flake in your project](#use-this-flake-in-your-project)
- [Override the Playwright CLI version](#override-the-playwright-cli-version)
- [Supported platforms](#supported-platforms)
- [Notes](#notes)

## Usage

Run directly from GitHub without cloning:

```bash
nix run github:kennethhoff/playwright-cli-flake#playwright-cli
```

Run from this repo:

```bash
nix run .
```

Build the package:

```bash
nix build .#playwright-cli
```

## Use this flake in your project

Add this flake as an input and include the package in your dev shell.

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    playwright-cli.url = "github:kennethhoff/playwright-cli-flake";
  };

  outputs = {
    self,
    nixpkgs,
    playwright-cli,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        playwright-cli.packages.${system}.playwright-cli
      ];
    };
  };
}
```

Then run `nix develop` and use `playwright`.

## Override the Playwright CLI version

The package is parameterized by `version`, `fileVersion`, and `hash`.

If you want to use a different Playwright CLI version, override these values:

```nix
let
  playwright = playwright-cli.packages.${system}.playwright-cli.override {
    version = "<playwright-version>";
    fileVersion = "<file-version>"; # defaults to version if omitted
    hash = "<nix-hash>";
  };
in {
  devShells.${system}.default = pkgs.mkShell {
    packages = [playwright];
  };
}
```

To get the correct `hash` for a new version, run a build once and copy the `got: ...` hash from the failure message.

## Supported platforms

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## Notes

- Versions are updated weekly via GitHub Actions.
