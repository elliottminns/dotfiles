{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/virtualisation/qemu-vm.nix")];

  networking.hostName = "zenbox-builder";
  networking.nameservers = ["1.1.1.1" "1.0.0.1"];
  networking.dhcpcd.extraConfig = "nooption domain_name_servers";
  services.resolved.enable = false;
  services.tailscale.enable = true;
  services.tailscale.openFirewall = true;

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AllowUsers = ["nix-ssh"];
      AllowAgentForwarding = false;
      AllowTcpForwarding = false;
      X11Forwarding = false;
    };
  };
  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [22];
  # The forced Nix command limits the SSH interface. Nix trust is still
  # root-equivalent INSIDE this disposable VM, never on the Zenbox host.
  nix.sshServe = {
    enable = true;
    protocol = "ssh-ng";
    write = true;
    trusted = true;
    keys = [(lib.trim (builtins.readFile ./vps-builder.pub))];
  };
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    sandbox = true;
    max-jobs = 2;
    cores = 4;
    allowed-users = ["root" "nix-ssh"];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  users.mutableUsers = false;
  # Administrative access is through the host's protected guest-agent socket.
  users.allowNoPasswordLogin = true;
  users.users.root.initialHashedPassword = lib.mkForce "!";
  services.getty.autologinUser = lib.mkForce null;
  system.stateVersion = "26.05";

  virtualisation = {
    graphics = false;
    cores = 8;
    memorySize = 16384;
    diskSize = 131072;
    diskImage = "/var/lib/zenbox-builder/root.qcow2";
    useNixStoreImage = true;
    mountHostNixStore = false;
    writableStore = true;
    writableStoreUseTmpfs = false;
    useHostCerts = false;
    sharedDirectories = lib.mkForce {};
    forwardPorts = [];
    qemu = {
      forceAccel = true;
      networkingOptions = lib.mkForce [
        "-netdev user,id=user.0,ipv6=off"
        "-device virtio-net-pci,netdev=user.0"
      ];
      # Host-root-only management, without an admin SSH key inside the VM.
      options = [
        "-device virtio-serial"
        "-chardev socket,path=/run/zenbox-builder/agent.sock,server=on,wait=off,id=qga0"
        "-device virtserialport,chardev=qga0,name=org.qemu.guest_agent.0"
      ];
    };
  };
}
