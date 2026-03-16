{
  lib,
  stdenv,
  version,
  fileVersion ? version,
  hash,
}:
stdenv.mkDerivation {
  pname = "playwright-cli";
  inherit version;

  # TODO

  meta = {
    description = "Playwright CLI";
    homepage = "https://playwright.dev/";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "playwright";
  };
}
