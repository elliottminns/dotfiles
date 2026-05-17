{
  lib,
  meta,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs;
    [
      blackmagic-desktop-video-vendor
      usbutils
      ffmpeg-full
      # Video/Audio data composition framework tools like "gst-inspect", "gst-launch" ...
      gst_all_1.gstreamer
      # Common plugins like "filesrc" to combine within e.g. gst-launch
      gst_all_1.gst-plugins-base
      # Specialized plugins separated by quality
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      # Plugins to reuse ffmpeg to play almost every video format
      gst_all_1.gst-libav
      # Support the Video Audio (Hardware) Acceleration API
      gst_all_1.gst-vaapi
    ]
    ++ lib.optionals (meta.hostname == "zenbox") [
      blackmagic-desktop-video-gui
    ];

  services.udev.extraRules = lib.mkIf (meta.hostname == "zenbox") ''
    ACTION=="add", KERNEL=="blackmagic/io[0-9]*", MODE="0666", RUN+="${pkgs.blackmagic-desktop-video-gui}/bin/DesktopVideoNotifier add /dev/%k"
    ACTION=="remove", KERNEL=="blackmagic/io[0-9]*", RUN+="${pkgs.blackmagic-desktop-video-gui}/bin/DesktopVideoNotifier del /dev/%k"
    ACTION=="add", KERNEL=="blackmagic/ttyio[0-9]*", MODE="0666"

    SUBSYSTEM=="usb", ATTRS{idVendor}=="1edb", ATTRS{idProduct}=="be13", MODE="0666"
  '';

  systemd.tmpfiles.rules = lib.mkIf (meta.hostname == "zenbox") [
    "d /etc/blackmagic 0755 root root -"
  ];

  systemd.services.DesktopVideoHelper.serviceConfig.ExecStart = lib.mkIf (meta.hostname == "zenbox") (lib.mkForce [
    ""
    "${pkgs.blackmagic-desktop-video-vendor}/bin/DesktopVideoHelper -n"
  ]);
}
