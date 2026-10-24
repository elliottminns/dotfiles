# Studiobox

Framework Desktop filming host with GNOME, shared GNOME preferences, a shared
Home Manager profile, Tailscale, SSH, and PipeWire. Common system settings and
Elliott's account are defined in `../../modules/workstation-base.nix`; common
Home Manager settings (shells, terminals, editors, Git, GPG, and applications)
live in `../../home/common.nix`. Recording applications and
capture-card drivers can be added once the filming hardware is decided.

## Fan RGB

Open **Fan RGB** from GNOME's app search to choose a color or turn the fan LEDs
off. The same controls are available from a terminal:

```sh
fan-rgb '#a855f7'
fan-rgb off
```

The last selection is restored at boot by `framework-fan-rgb.service`. This uses
the nixpkgs `framework-tool` package through `/dev/cros_ec` to control the
Framework Desktop fan's eight LEDs.

## Secrets

The repository's `.sops.yaml` encrypts `secrets/shared.yaml` to Elliott's existing
YubiKey-backed GPG key. This is the shared source for all machines; studiobox is
the first configured consumer. Create it locally using SOPS, with these two string keys:

- `luks_password`: the disk passphrase (a nonempty, single-line string).
- `tailscale_auth_key`: a reusable Tailscale enrollment key for the machines using this file.

From the flake directory, enter a shell with the provisioning tools and create the
file (it does not exist until the first successful save). Import your public GPG key and connect the YubiKey on the installer first;
`gpg --card-status` should detect it. Enter real values in the SOPS editor, and
commit only the resulting encrypted YAML.

```sh
nix shell nixpkgs#sops nixpkgs#ssh-to-age nixpkgs#gnupg nixpkgs#openssh
EDITOR=nvim sops --config .sops.yaml edit secrets/shared.yaml
```

Replace the editor's default example with the following keys and your real
values, then save and exit. SOPS writes the encrypted YAML to the requested path:

```yaml
luks_password: "your shared disk passphrase"
tailscale_auth_key: "your reusable Tailscale enrollment key"
```

The helper runs as your normal user so decryption uses your GPG agent. It invokes
sudo for writes into the installed system. No credential values go through Nix
expressions, shell arguments, or the Nix store.

## Installation

1. Confirm the disk in `disko-config.nix`: `/dev/nvme0n1` is a placeholder.
   Disko in disko mode erases the selected disk. The layout follows zenbox: a
   1 GiB EFI partition and LUKS-encrypted Btrfs with a 16 GiB swapfile.
2. Decrypt the disk password with your YubiKey into the installer's RAM-backed
   `/run`, then partition and mount the disk:

   ```sh
   bash machines/studiobox/prepare-secrets.sh disk-key
   sudo nix run github:nix-community/disko -- --mode disko machines/studiobox/disko-config.nix
   rm -f /run/studiobox/luks-password
   ```

3. Generate the target hardware config using
   `sudo nixos-generate-config --no-filesystems --root /mnt`, then copy
   `/mnt/etc/nixos/hardware-configuration.nix` into `machines/studiobox/`.
4. Prepare the SSH host identity and deployed secrets **before nixos-install**:

   ```sh
   bash machines/studiobox/prepare-secrets.sh deploy /mnt
   ```

   This encrypts a deployed copy to both your YubiKey recipient and the new
   machine's SSH host key, and installs it at `/mnt/var/lib/sops/shared.yaml`.
   The repository copy keeps your YubiKey recipient only. The host identity
   must be preserved; replacing it requires running this step again.
5. Ensure the new Nix files and encrypted YAML are tracked by Git, then install
   with `sudo nixos-install --flake .#studiobox`.
6. Elliott's existing password hash and YubiKey SSH public key are configured
   declaratively; no manual password setup is needed.

Studiobox sets `users.mutableUsers = false` so activation enforces the configured
password hash. Verify `nixos-enter --root /mnt -c 'passwd -S elliott'` reports
`P` (a usable password), rather than `L` (locked), before rebooting.

### Remote installation with nixos-anywhere

The confirmed target is `root@192.168.0.6`; `/dev/nvme0n1` is the Samsung
990 PRO 4 TB SSD. Reconfirm these before any future reinstall.

Generate hardware settings over SSH with
`nixos-generate-config --show-hardware-config --no-filesystems`. Prepare a private
staging directory outside the repository containing the decrypted disk password
and an `extra/` tree with `etc/ssh/ssh_host_ed25519_key` (and `.pub`) and
`var/lib/sops/shared.yaml`. Encrypt the deployed YAML to that host key's age
recipient and Elliott's GPG recipient, as in `prepare-secrets.sh`.

```sh
nix run nixpkgs#nixos-anywhere -- \
  --flake "path:$PWD#studiobox" \
  --target-host root@192.168.0.6 \
  --extra-files "$staging/extra" \
  --disk-encryption-keys /run/studiobox/luks-password "$staging/luks-password" \
  --phases kexec,disko,install --build-on local
```

Here `$staging` must point to that prepared directory. This command erases the
configured disk and stops before reboot. Elliott's existing password hash is
configured declaratively.

Remove the local staging directory and the installer's
`/run/studiobox/luks-password` after installation, then reboot and enter the disk
passphrase at the physical console.

At boot, enter the disk passphrase normally. SOPS-nix decrypts the Tailscale key
as root after the encrypted root is mounted; Tailscale then enrolls automatically.
This does not configure automatic disk unlock or YubiKey FIDO2 disk enrollment.
The disk password cannot be loaded from SOPS on the encrypted root before unlock.

## Updating credentials

Edit `secrets/shared.yaml` with SOPS and rerun the deploy helper on studiobox,
using `/` as the target root. Restart `sops-install-secrets.service` followed by
`tailscaled-autoconnect.service` after updating the encrypted deployed file.
Tailscale keeps its identity in `/var/lib/tailscale`; an expired enrollment key
does not require re-enrollment of an already connected machine.

Changing `luks_password` in SOPS does not change an existing LUKS keyslot; update
the disk passphrase with `cryptsetup luksChangeKey` as part of any rotation.
Subsequent rebuilds use `sudo nixos-rebuild switch --flake .#studiobox`.
