{pkgs, ...}: let
  fanRgb = pkgs.writeScriptBin "fan-rgb" ''
    #!${pkgs.python3}/bin/python3
    FRAMEWORK_TOOL = "${pkgs.framework-tool}/bin/framework_tool"
    ZENITY = "${pkgs.zenity}/bin/zenity"
    ${builtins.readFile ./fan-rgb.py}
  '';
  launcher = pkgs.makeDesktopItem {
    name = "fan-rgb";
    desktopName = "Fan RGB";
    comment = "Set the Framework Desktop fan lighting";
    exec = "${fanRgb}/bin/fan-rgb";
    icon = "preferences-color";
    categories = ["Settings" "HardwareSettings"];
  };
in {
  environment.systemPackages = [pkgs.framework-tool fanRgb launcher];

  systemd.services.framework-fan-rgb = {
    description = "Restore Framework Desktop fan lighting";
    wantedBy = ["multi-user.target"];
    after = ["systemd-modules-load.service"];
    unitConfig.ConditionPathExists = "/var/lib/framework-fan-rgb/color";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${fanRgb}/bin/fan-rgb --restore";
      StateDirectory = "framework-fan-rgb";
      StateDirectoryMode = "0755";
    };
  };
}
