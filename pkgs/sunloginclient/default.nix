{ stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, lib
, makeWrapper
, xorg
, libstdcxx5
, glibc
, libgcc
, libuuid
, webkitgtk
, libappindicator-gtk3
, systemd
}:

stdenv.mkDerivation rec {
  pname = "sunloginclient-${version}";
  version = "10.1.1.28779";
  src = fetchurl {
    url = "https://dw.oray.com/sunlogin/linux/sunloginclientshell-${version}-amd64.deb";
    sha256 = "sha256-kjqL/bEZTuUNjG3XtRoPFqs0s0FMdo9f+itJ2Ah07tU=";
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
    libstdcxx5
    glibc
    libgcc
    libuuid
    webkitgtk
    libappindicator-gtk3
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
  '';

  meta = with lib; {
    description = "Sunlogin Remote Control Client";
    homepage = "https://sunlogin.oray.com/";
    license = licenses.MIT;
    platforms = [ "x86_64-linux" ];
  };
}