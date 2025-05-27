{
  lib,
  callPackage,
  fetchFromGitHub,
  stdenv,
  wrapGAppsHook3,
}: let
  pname = "easytier-gui";
  version = "2.2.3";

  src = fetchFromGitHub {
    owner = "EasyTier";
    repo = "EasyTier";
    tag = "v${version}";
    hash = "sha256-y2MGxCWL6mDlFDyDjhZOFo7djN09EZgTJsjXL+E7p/s=";
  };

  pnpm-hash = "sha256-l+uFiM1sW3n4aLHf9lj8G5wNYJlZMG8o8x//H9C64So=";
  vendor-hash = "sha256-1s6I25shJZQXO+rjxffl+Eab237ktQCdXlaFKMPkq0M=";

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
    longDescription = ''
      EasyTier GUI based on tauri
      Setting NixOS option `programs.easytier-gui.enable = true` is recommended.
    '';
    license = lib.licenses.asl20;
    mainProgram = "easytier-gui";
    platforms = lib.platforms.linux;
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

    # Fix libayatana-appindicator unable to get session bus, but this will slow down the startup time by about 20s.
    # preFixup = ''
    #   gappsWrapperArgs+=(
    #     # --set DBUS_SESSION_BUS_ADDRESS "unix:path=/run/user/$(id -u)/bus"
    #   )
    # '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{bin,share}
      cp -r ${unwrapped}/share/* $out/share
      cp -r ${unwrapped}/bin/easytier-gui $out/bin/easytier-gui
      runHook postInstall
    '';
  }
