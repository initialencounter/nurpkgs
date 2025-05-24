{ pkgs, stdenv }:

let
  sources = import ./sources.nix {};
  srcs = {
    x86_64-linux = pkgs.fetchurl {
      url = sources.easytier_amd64_url;
      hash = sources.easytier_amd64_hash;
    };
    aarch64-linux = pkgs.fetchurl {
      url = sources.easytier_arm64_url;
      hash = sources.easytier_arm64_hash;
    };
  };
  currentSystem = pkgs.stdenv.hostPlatform.system;
in 
stdenv.mkDerivation rec {
  pname = "easytier";
  version = sources.easytier_version;
  src = srcs.${currentSystem} or (throw "Unsupported system: ${currentSystem}");
  nativeBuildInputs = with pkgs;[
    unzip
  ];
  unpackPhase = "unzip $src -d easylinux-linux";
  installPhase = ''
    mkdir -p $out/bin
    cp -r easylinux-linux/easytier-linux*/* $out/bin/
  '';
}
