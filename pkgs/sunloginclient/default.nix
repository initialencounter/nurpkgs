{ stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, lib
, makeWrapper
, xorg
, libappindicator-gtk3
, systemd
, ncurses5
, libxcrypt-legacy
, nss
, alsa-lib
, libXScrnSaver
, pkgs
, unzip
, patchelf
}:

let
  libcrypt-compat = stdenv.mkDerivation {
    name = "libcrypt-compat";
    buildInputs = [ libxcrypt-legacy ];
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/lib
      ln -s ${libxcrypt-legacy}/lib/libcrypt.so $out/lib/libcrypt.so.1
    '';
  };

  libwidevinecdm-compat = stdenv.mkDerivation rec {
    pname = "widevine-cdm";
    version = "4.10.2710.0";
    src = fetchurl {
      url = "https://dl.google.com/widevine-cdm/${version}-linux-x64.zip";
      sha256 = "sha256-wSDl0Dym61JD1MaaakNI4SEjOCSrJtuRJqU7qZcJ0VI=";
    };
    nativeBuildInputs = [ unzip ];
    unpackPhase = "unzip $src";
    installPhase = ''
      mkdir -p $out/lib
      cp libwidevinecdm.so $out/lib/
    '';
  };
in

stdenv.mkDerivation rec {
  pname = "sunloginclient";
  version = "15.2.0.63064";
  src = fetchurl {
    url = "https://dw.oray.com/sunlogin/linux/SunloginClient_${version}_amd64.deb";
    sha256 = "sha256-3a5dNk64tpQGoOGDSQRQ/S+R8HKXKzcI6VGOiFLLimM=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    patchelf
  ];

  buildInputs = [
    xorg.libX11
    xorg.libXtst
    xorg.libXrandr
    xorg.libXinerama
    xorg.libxcb
    xorg.libXext
    xorg.libXi
    xorg.libXrender
    xorg.libXau
    libappindicator-gtk3
    ncurses5
    libcrypt-compat
    nss
    alsa-lib
    libXScrnSaver
    pkgs.gnome2.GConf
    libwidevinecdm-compat
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir -p $out
    cp -r usr/local/sunlogin/* $out/

    mkdir -p $out/share/applications
    cp usr/share/applications/sunlogin.desktop $out/share/applications/

    substituteInPlace $out/share/applications/sunlogin.desktop \
      --replace "/usr/local/sunlogin" "$out"
    
    if [ -d "usr/share/icons" ]; then
      mkdir -p $out/share/icons
      cp -r usr/share/icons/* $out/share/icons/
    fi

    mkdir -p $out/etc/systemd/system
    cat > $out/etc/systemd/system/runsunloginclient.service <<EOF
    [Unit]
    Description=Sunlogin Client
    After=network.target
    
    [Service]
    Type=forking
    ExecStart=$out/scripts/start.sh
    ExecStop=$out/scripts/stop.sh
    Restart=on-failure
    
    [Install]
    WantedBy=multi-user.target
    EOF
  '';

  autoPatchelfLibs = [ "$out/lib" ];
  
  postFixup = ''
    # 修复脚本路径
    substituteInPlace $out/scripts/start.sh \
      --replace "/usr/local/sunlogin" "$out"
    substituteInPlace $out/scripts/stop.sh \
      --replace "/usr/local/sunlogin" "$out"
    substituteInPlace $out/scripts/depends.sh \
      --replace "/usr/local/sunlogin" "$out"
    
    chmod +x $out/scripts/*.sh
    chmod +x $out/share/applications/sunlogin.desktop
    
    # 设置正确的 RPATH
    find $out -type f -executable -exec patchelf --set-rpath "$out/lib:${lib.makeLibraryPath buildInputs}" {} \;
    
    # 包装主程序
    if [ -f "$out/bin/sunloginclient" ]; then
      wrapProgram $out/bin/sunloginclient \
        --prefix LD_LIBRARY_PATH : "$out/lib:${lib.makeLibraryPath buildInputs}"
    fi
    
    # 确保 libcef.so 可执行
    chmod +x $out/lib/libcef.so
  '';

  meta = with lib; {
    description = "Sunlogin Remote Control Client";
    homepage = "https://sunlogin.oray.com/";
    platforms = [ "x86_64-linux" ];
  };
}