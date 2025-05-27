{
  pname,
  version,
  src,
  meta,

  pnpm-hash,
  vendor-hash,

  rustPlatform,

  cargo-tauri,
  jq,
  moreutils,
  nodejs,
  pkg-config,
  pnpm_9,

  glib,
  kdePackages,
  libayatana-appindicator,
  libsForQt5,
  libsoup,
  openssl,
  webkitgtk_4_1,
}:

rustPlatform.buildRustPackage {
  inherit version src meta;
  pname = "${pname}-unwrapped";

  cargoRoot = ".";
  buildAndTestSubdir = "easytier-gui/src-tauri";

  useFetchCargoVendor = true;
  cargoHash = vendor-hash;

  pnpmDeps = pnpm_9.fetchDeps {
    inherit pname version src;
    hash = pnpm-hash;
  };

  env = {
    OPENSSL_NO_VENDOR = 1;
  };

  postPatch = ''
    # We disable the option to try to use the bleeding-edge version of mihomo
    # If you need a newer version, you can override the mihomo input of the wrapped package

    substituteInPlace $cargoDepsCopy/libappindicator-sys-*/src/lib.rs \
      --replace-fail "libayatana-appindicator3.so.1" "${libayatana-appindicator}/lib/libayatana-appindicator3.so.1"

    substituteInPlace easytier-gui/src-tauri/tauri.conf.json \
      --replace-fail "pnpm build" "pnpm -r build"

    # this file tries to override the linker used when compiling for certain platforms
    rm .cargo/config.toml

    # disable updater and don't try to bundle helper binaries
    jq '
      .bundle.createUpdaterArtifacts = false |
      del(.bundle.resources) |
      del(.bundle.externalBin)
    ' easytier-gui/src-tauri/tauri.conf.json | sponge easytier-gui/src-tauri/tauri.conf.json
  '';

  nativeBuildInputs = [
    cargo-tauri.hook
    jq
    moreutils
    nodejs
    pkg-config
    pnpm_9.configHook
  ];

  buildInputs = [
    libayatana-appindicator
    libsoup
    openssl
    webkitgtk_4_1
  ];

  # make sure the .desktop file name does not contain whitespace,
  # so that the service can register it as an auto-start item
  postInstall = ''
    mv $out/share/applications/easytier-gui.desktop $out/share/applications/easytier-gui.desktop
  '';
}