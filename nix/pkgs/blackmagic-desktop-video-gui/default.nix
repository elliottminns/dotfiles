{
  autoPatchelfHook,
  alsa-lib,
  avahi,
  avahi-compat,
  blackmagic-desktop-video-vendor,
  dbus,
  fontconfig,
  freetype,
  gcc,
  glib,
  lib,
  libice,
  libGL,
  libdrm,
  libsm,
  libusb1,
  libx11,
  libxcb,
  libxext,
  libxi,
  libxkbfile,
  libxrender,
  krb5,
  libxkbcommon,
  makeWrapper,
  nspr,
  nss,
  stdenv,
  xcb-util-cursor,
  xcbutilimage,
  xcbutilkeysyms,
  xcbutilrenderutil,
  xcbutilwm,
  zstd,
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
    alsa-lib
    avahi
    avahi-compat
    fontconfig
    freetype
    gcc.cc.lib
    glib
    libGL
    libdrm
    libice
    libsm
    libusb1
    libx11
    libxcb
    libxext
    libxrender
    krb5
    libxkbcommon
    nspr
    nss
    xcb-util-cursor
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    xcbutilwm
    libxi
    libxkbfile
    zstd
  ];

  unpackPhase = ''
    runHook preUnpack

    tar xf $src
    mkdir gui main

    guiDeb=(Blackmagic_Desktop_Video_Linux_${finalAttrs.version}/deb/x86_64/desktopvideo-gui_*_amd64.deb)
    ar x "''${guiDeb[0]}" --output gui
    tar xf gui/data.tar.xz -C gui

    mainDeb=(Blackmagic_Desktop_Video_Linux_${finalAttrs.version}/deb/x86_64/desktopvideo_*_amd64.deb)
    ar x "''${mainDeb[0]}" --output main
    tar xf main/data.tar.xz -C main

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/blackmagic/DesktopVideo $out/share

    cp -r gui/usr/lib/blackmagic/DesktopVideo/. $out/lib/blackmagic/DesktopVideo/
    cp -r main/usr/lib/blackmagic/DesktopVideo/Firmware $out/lib/blackmagic/DesktopVideo/
    cp main/usr/lib/blackmagic/DesktopVideo/libDVUpdate.so $out/lib/blackmagic/DesktopVideo/
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
