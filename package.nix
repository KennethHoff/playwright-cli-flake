{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchurl,
  makeWrapper,
  stdenvNoCC,
  symlinkJoin,
  unzip,
  stdenv,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gobject-introspection,
  gtk3,
  libdrm,
  libgbm,
  libpulseaudio,
  libxkbcommon,
  nspr,
  nss,
  pango,
  systemd,
  udev,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  version,
  srcHash,
  npmDepsHash,
  chromiumRevision,
  chromiumBrowserVersion,
  chromiumHashes,
}:
let
  # Chrome for Testing platform tag for the current host.
  cftPlatform =
    {
      "x86_64-linux" = "linux64";
      "x86_64-darwin" = "mac-x64";
      "aarch64-darwin" = "mac-arm64";
    }
    .${stdenv.hostPlatform.system} or null;

  hostHashes = chromiumHashes.${stdenv.hostPlatform.system} or null;

  # Build one browser dir matching Playwright's expected on-disk layout:
  # <out>/<dirName>-<revision>/<zip-toplevel>/  plus marker files.
  mkBrowser =
    {
      zipName,
      dirName,
      hash,
    }:
    stdenvNoCC.mkDerivation {
      pname = "playwright-${dirName}";
      version = chromiumRevision;
      src = fetchurl {
        url = "https://cdn.playwright.dev/builds/cft/${chromiumBrowserVersion}/${cftPlatform}/${zipName}-${cftPlatform}.zip";
        inherit hash;
      };
      nativeBuildInputs = [ unzip ];
      dontUnpack = true;
      installPhase = ''
        runHook preInstall
        mkdir -p "$out/${dirName}-${chromiumRevision}"
        unzip -q "$src" -d "$out/${dirName}-${chromiumRevision}"
        touch "$out/${dirName}-${chromiumRevision}/INSTALLATION_COMPLETE"
        touch "$out/${dirName}-${chromiumRevision}/DEPENDENCIES_VALIDATED"
        runHook postInstall
      '';
    };

  browsersDir = lib.optionalAttrs (cftPlatform != null && hostHashes != null) {
    out = symlinkJoin {
      name = "playwright-browsers-cft-${chromiumBrowserVersion}";
      paths = [
        (mkBrowser {
          zipName = "chrome";
          dirName = "chromium";
          hash = hostHashes.chromium;
        })
        (mkBrowser {
          zipName = "chrome-headless-shell";
          dirName = "chromium_headless_shell";
          hash = hostHashes.headless;
        })
      ];
    };
  };

  # Native shared libs Chromium/WebKit dlopen at runtime when launched via
  # `playwright-cli`. Linux only; Darwin browsers come self-contained.
  browserDeps = lib.optionals stdenv.isLinux [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib
    gobject-introspection
    gtk3
    libdrm
    libgbm
    libpulseaudio
    libxkbcommon
    nspr
    nss
    pango
    systemd
    udev
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
  ];
in
buildNpmPackage {
  pname = "playwright-cli";
  inherit version;

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "playwright-cli";
    rev = "v${version}";
    hash = srcHash;
  };

  inherit npmDepsHash;

  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = browserDeps;

  env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

  postFixup =
    lib.optionalString stdenv.isLinux ''
      wrapProgram $out/bin/playwright-cli \
        ${lib.optionalString (browsersDir ? out) "--set-default PLAYWRIGHT_BROWSERS_PATH ${browsersDir.out}"} \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath browserDeps}"
    ''
    + lib.optionalString (stdenv.isDarwin && browsersDir ? out) ''
      wrapProgram $out/bin/playwright-cli \
        --set-default PLAYWRIGHT_BROWSERS_PATH ${browsersDir.out}
    '';

  meta = {
    description = "Playwright CLI";
    homepage = "https://playwright.dev/";
    license = lib.licenses.mit;
    mainProgram = "playwright-cli";
  };
}
