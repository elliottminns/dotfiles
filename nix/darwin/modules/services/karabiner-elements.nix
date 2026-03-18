{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.karabiner-elements;

  parentAppDir = "/Applications/.Nix-Karabiner";
  packageAppSupport = "${cfg.package}/Library/Application Support/org.pqrs/Karabiner-Elements";
  driverAppSupport = "${cfg.package.driver}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice";
  nonPrivilegedLaunchAgentsDir =
    "${packageAppSupport}/Karabiner-Elements Non-Privileged Agents v2.app/Contents/Library/LaunchAgents";
in
{
  options.services.karabiner-elements = {
    enable = mkEnableOption "Karabiner-Elements";
    package = mkPackageOption pkgs "karabiner-elements" { };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    system.activationScripts.preActivation.text = ''
      rm -rf ${parentAppDir}
      mkdir -p ${parentAppDir}
      # The system extension manager must live under /Applications.
      cp -r ${cfg.package.driver}/Applications/.Karabiner-VirtualHIDDevice-Manager.app ${parentAppDir}
    '';

    system.activationScripts.postActivation.text = ''
      echo "attempt to activate karabiner system extension and start daemons" >&2
      launchctl unload /Library/LaunchDaemons/org.nixos.start_karabiner_daemons.plist || true
      launchctl load -w /Library/LaunchDaemons/org.nixos.start_karabiner_daemons.plist
    '';

    launchd.daemons.start_karabiner_daemons = {
      script = ''
        ${parentAppDir}/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
        launchctl kickstart system/org.pqrs.service.daemon.Karabiner-Core-Service
        launchctl kickstart system/org.pqrs.service.daemon.Karabiner-VirtualHIDDevice-Daemon
      '';
      serviceConfig.Label = "org.nixos.start_karabiner_daemons";
      serviceConfig.RunAtLoad = true;
    };

    launchd.daemons.Karabiner-Core-Service = {
      serviceConfig.ProgramArguments = [
        "${packageAppSupport}/Karabiner-Core-Service.app/Contents/MacOS/Karabiner-Core-Service"
      ];
      serviceConfig.ProcessType = "Interactive";
      serviceConfig.Label = "org.pqrs.service.daemon.Karabiner-Core-Service";
      serviceConfig.KeepAlive = true;
    };

    launchd.daemons.Karabiner-VirtualHIDDevice-Daemon = {
      serviceConfig.ProgramArguments = [
        "${driverAppSupport}/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
      ];
      serviceConfig.ProcessType = "Interactive";
      serviceConfig.Label = "org.pqrs.service.daemon.Karabiner-VirtualHIDDevice-Daemon";
      serviceConfig.KeepAlive = true;
    };

    launchd.user.agents.activate_karabiner_system_ext = {
      serviceConfig.ProgramArguments = [
        "${parentAppDir}/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"
        "activate"
      ];
      serviceConfig.RunAtLoad = true;
      managedBy = "services.karabiner-elements.enable";
    };

    # karabiner_session_monitor still needs a setuid wrapper outside the store.
    launchd.daemons.setsuid_karabiner_session_monitor = {
      script = ''
        rm -rf /run/wrappers
        mkdir -p /run/wrappers/bin
        install -m4555 "${packageAppSupport}/bin/karabiner_session_monitor" /run/wrappers/bin
      '';
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive.SuccessfulExit = false;
    };

    launchd.user.agents.karabiner_session_monitor = {
      serviceConfig.ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path /run/wrappers/bin && /run/wrappers/bin/karabiner_session_monitor"
      ];
      serviceConfig.Label = "org.pqrs.service.agent.karabiner_session_monitor";
      serviceConfig.KeepAlive = true;
      managedBy = "services.karabiner-elements.enable";
    };

    environment.userLaunchAgents."org.pqrs.service.agent.Karabiner-Core-Service.plist".source =
      "${nonPrivilegedLaunchAgentsDir}/org.pqrs.service.agent.Karabiner-Core-Service.plist";
    environment.userLaunchAgents."org.pqrs.service.agent.Karabiner-Menu.plist".source =
      "${nonPrivilegedLaunchAgentsDir}/org.pqrs.service.agent.Karabiner-Menu.plist";
    environment.userLaunchAgents."org.pqrs.service.agent.Karabiner-MultitouchExtension.plist".source =
      "${nonPrivilegedLaunchAgentsDir}/org.pqrs.service.agent.Karabiner-MultitouchExtension.plist";
    environment.userLaunchAgents."org.pqrs.service.agent.Karabiner-NotificationWindow.plist".source =
      "${nonPrivilegedLaunchAgentsDir}/org.pqrs.service.agent.Karabiner-NotificationWindow.plist";
    environment.userLaunchAgents."org.pqrs.service.agent.karabiner_console_user_server.plist".source =
      "${nonPrivilegedLaunchAgentsDir}/org.pqrs.service.agent.karabiner_console_user_server.plist";
  };
}
