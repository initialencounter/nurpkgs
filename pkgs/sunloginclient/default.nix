{ stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, lib
, makeWrapper
, xorg
, gcc
, glibc
, libgcc
, libuuid
, webkitgtk
, libappindicator-gtk3
, systemd
, ncurses5
, libxcrypt-legacy
}:

let
  # 创建兼容层
  # https://github.com/luisholanda/dotfiles/blob/dc947fe00d89c089617f779fd2aa6f72f68904b7/overlays/applications/games/steam.nix#L17
  libcrypt-compat = stdenv.mkDerivation {
    name = "libcrypt-compat";
    buildInputs = [ libxcrypt-legacy ];
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/lib
      ln -s ${libxcrypt-legacy}/lib/libcrypt.so $out/lib/libcrypt.so.1
    '';
  };
in

stdenv.mkDerivation rec {
  pname = "sunloginclient-${version}";
  version = "15.2.0.63064";
  src = fetchurl {
    url = "https://dw.oray.com/sunlogin/linux/SunloginClient_${version}_amd64.deb";
    sha256 = "sha256-3a5dNk64tpQGoOGDSQRQ/S+R8HKXKzcI6VGOiFLLimM=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
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
    gcc.cc.lib
    glibc
    libgcc
    libuuid
    webkitgtk
    libappindicator-gtk3
    ncurses5
    libcrypt-compat
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir -p $out/usr/local/sunlogin
    cp -r usr/local/sunlogin/bin $out/usr/local/sunlogin/
    cp -r usr/local/sunlogin/scripts $out/usr/local/sunlogin/
    
    # 创建必要的符号链接
    mkdir -p $out/bin
    ln -s $out/usr/local/sunlogin/bin/sunloginclient $out/bin/sunloginclient
    ln -s $out/usr/local/sunlogin/bin/oray_rundaemon $out/bin/oray_rundaemon
    
    # 安装 .desktop 文件
    mkdir -p $out/share/applications
    cp usr/share/applications/sunlogin.desktop $out/share/applications/

    # 修复 .desktop 文件中的路径
    substituteInPlace $out/share/applications/sunlogin.desktop \
      --replace "/usr/local/sunlogin" "$out/usr/local/sunlogin"
    
    # 安装图标（如果有）
    if [ -d "usr/share/icons" ]; then
      mkdir -p $out/share/icons
      cp -r usr/share/icons/* $out/share/icons/
    fi

    # 创建systemd服务文件
    mkdir -p $out/etc/systemd/system
    cat > $out/etc/systemd/system/runsunloginclient.service <<EOF
    [Unit]
    Description=Sunlogin Client
    After=network.target
    
    [Service]
    Type=forking
    ExecStart=$out/usr/local/sunlogin/scripts/start.sh
    ExecStop=$out/usr/local/sunlogin/scripts/stop.sh
    Restart=on-failure
    
    [Install]
    WantedBy=multi-user.target
    EOF
  '';

  postFixup = ''
    # 修复脚本中的路径
    substituteInPlace $out/usr/local/sunlogin/scripts/start.sh \
      --replace "/usr/local/sunlogin" "$out/usr/local/sunlogin"
    substituteInPlace $out/usr/local/sunlogin/scripts/stop.sh \
      --replace "/usr/local/sunlogin" "$out/usr/local/sunlogin"
    substituteInPlace $out/usr/local/sunlogin/scripts/depends.sh \
      --replace "/usr/local/sunlogin" "$out/usr/local/sunlogin"
    
    chmod +x $out/usr/local/sunlogin/scripts/*.sh
    # 确保 .desktop 文件可执行
    chmod +x $out/share/applications/sunlogin.desktop
  '';

  meta = with lib; {
    description = "Sunlogin Remote Control Client";
    homepage = "https://sunlogin.oray.com/";
    platforms = [ "x86_64-linux" ];
  };
}