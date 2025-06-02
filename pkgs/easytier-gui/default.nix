{
  lib,
  callPackage,
  fetchFromGitHub,
  stdenv,
  wrapGAppsHook3,
}: let
  pname = "easytier-gui";
  version = "2.2.4";

  src = fetchFromGitHub {
    owner = "EasyTier";
    repo = "EasyTier";
    tag = "v${version}";
    hash = "sha256-YrWuNHpNDs1VVz6Sahi2ViPT4kcJf10UUMRWEs4Y0xc=";
  };

  pnpm-hash = "sha256-l+uFiM1sW3n4aLHf9lj8G5wNYJlZMG8o8x//H9C64So=";
  vendor-hash = "sha256-uUmF4uIhSx+byG+c4hlUuuy+O87Saw8wRJ5OGk3zaPA=";

  unwrapped = callPackage ./unwrapped.nix {
    inherit
      pname
      version
      src
      pnpm-hash
      vendor-hash
      meta
      ;
  };
  meta = {
    description = "EasyTier GUI based on tauri";
    homepage = "https://github.com/EasyTier/EasyTier";
    changelog = "https://github.com/EasyTier/EasyTier/releases/tag/v${version}";
    longDescription = ''
      EasyTier GUI based on tauri.
      EasyTier is a simple, safe and decentralized VPN networking solution implemented
      with the Rust language and Tokio framework.
    '';
    license = lib.licenses.asl20;
    mainProgram = "easytier-gui";
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [initialencounter];
  };
in
  stdenv.mkDerivation {
    inherit
      pname
      src
      version
      meta
      ;

    nativeBuildInputs = [
      wrapGAppsHook3
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{bin,share}
      cp -r ${unwrapped}/share/* $out/share
      cp -r ${unwrapped}/bin/easytier-gui $out/bin/easytier-gui
      runHook postInstall
    '';
  }
