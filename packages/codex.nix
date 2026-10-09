{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation rec {
  pname = "codex";
  version = "0.162.0";

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-package-x86_64-unknown-linux-musl.tar.gz";
    hash = "sha256-T1c5RMHSBZEJ11ovTQzJwDaXKIIkpeQHcXqd6Y/AEMU=";
  };

  sourceRoot = ".";
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R bin codex-package.json codex-path codex-resources $out/

    runHook postInstall
  '';

  meta = {
    description = "OpenAI's coding agent";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = [ "x86_64-linux" ];
  };
}
