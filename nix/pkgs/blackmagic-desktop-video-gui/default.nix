{
  autoPatchelfHook,
  blackmagic-desktop-video-vendor,
  dbus,
  fontconfig,
  freetype,
  gcc,
  glib,
  lib,
  libice,
  libGL,
  libsm,
  libusb1,
  libx11,
  libxcb,
  libxext,
  libxrender,
  makeWrapper,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "blackmagic-desktop-video-gui";
  inherit (blackmagic-desktop-video-vendor) version src;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    dbus
    fontconfig
    freetype
    gcc.cc.lib
    glib
    libGL
    libice
    libsm
    libusb1
    libx11
    libxcb
    libxext
    libxrender
  ];

  unpackPhase = ''
    runHook preUnpack

    tar xf $src
    mkdir gui main

    ar x Blackmagic_Desktop_Video_Linux_${finalAttrs.version}/deb/x86_64/desktopvideo-gui_16.0a14_amd64.deb \
      --output gui
    tar xf gui/data.tar.xz -C gui

    ar x Blackmagic_Desktop_Video_Linux_${finalAttrs.version}/deb/x86_64/desktopvideo_16.0a14_amd64.deb \
      --output main
    tar xf main/data.tar.xz -C main

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/blackmagic/DesktopVideo $out/share

    cp -r gui/usr/lib/blackmagic/DesktopVideo/. $out/lib/blackmagic/DesktopVideo/
    cp -r main/usr/lib/blackmagic/DesktopVideo/Firmware $out/lib/blackmagic/DesktopVideo/
    cp main/usr/lib/blackmagic/DesktopVideo/libDVUpdate.so $out/lib/blackmagic/DesktopVideo/
    cp main/usr/lib/blackmagic/DesktopVideo/libc++.so.1 $out/lib/blackmagic/DesktopVideo/
    cp main/usr/lib/blackmagic/DesktopVideo/libc++abi.so.1 $out/lib/blackmagic/DesktopVideo/
    cp main/usr/lib/blackmagic/DesktopVideo/libgcc_s.so.1 $out/lib/blackmagic/DesktopVideo/
    cp main/usr/lib/blackmagic/DesktopVideo/DesktopVideoUpdateTool $out/lib/blackmagic/DesktopVideo/
    cp main/usr/lib/blackmagic/DesktopVideo/DesktopVideoNotifier $out/lib/blackmagic/DesktopVideo/

    cp -r gui/usr/share/applications gui/usr/share/doc gui/usr/share/icons gui/usr/share/man $out/share/

    makeWrapper $out/lib/blackmagic/DesktopVideo/BlackmagicDesktopVideoSetup $out/bin/BlackmagicDesktopVideoSetup \
      --set QT_PLUGIN_PATH $out/lib/blackmagic/DesktopVideo/plugins \
      --set QT_QPA_PLATFORM_PLUGIN_PATH $out/lib/blackmagic/DesktopVideo/plugins/platforms \
      --prefix LD_LIBRARY_PATH : ${blackmagic-desktop-video-vendor}/lib

    makeWrapper $out/lib/blackmagic/DesktopVideo/DesktopVideoUpdater $out/bin/DesktopVideoUpdater \
      --set QT_PLUGIN_PATH $out/lib/blackmagic/DesktopVideo/plugins \
      --set QT_QPA_PLATFORM_PLUGIN_PATH $out/lib/blackmagic/DesktopVideo/plugins/platforms \
      --prefix LD_LIBRARY_PATH : ${blackmagic-desktop-video-vendor}/lib

    makeWrapper $out/lib/blackmagic/DesktopVideo/DesktopVideoUpdateTool $out/bin/DesktopVideoUpdateTool \
      --prefix LD_LIBRARY_PATH : ${blackmagic-desktop-video-vendor}/lib

    makeWrapper $out/lib/blackmagic/DesktopVideo/DesktopVideoNotifier $out/bin/DesktopVideoNotifier \
      --prefix LD_LIBRARY_PATH : ${blackmagic-desktop-video-vendor}/lib

    runHook postInstall
  '';

  meta = {
    homepage = "https://www.blackmagicdesign.com/support/family/capture-and-playback";
    description = "Blackmagic Desktop Video graphical setup and firmware update tools";
    license = lib.licenses.unfree;
    platforms = ["x86_64-linux"];
  };
})
