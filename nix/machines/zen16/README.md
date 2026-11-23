# zen16

Framework Laptop 16 (AMD Ryzen 7040 Series), Ryzen 9 7940HS with Radeon
7700S-class discrete graphics. Installer target: `root@192.168.0.48`.

Disko targets the WD_BLACK SN770M 2 TB SSD by its stable device ID. Running
the disk script destroys the existing contents. The layout uses a 4 GiB EFI
partition and LUKS-encrypted Btrfs with root, home, Nix, and swap subvolumes.

The disk passphrase comes from `luks_password` in `secrets/shared.yaml`.
Decrypt it directly into the installer's `/tmp/secret.key` with mode 0600;
never put plaintext secrets in this repository or the Nix store. Delete the
installer's passphrase file after partitioning. Enter that passphrase at boot.

The configuration reuses studiobox's SOPS module for Tailscale enrollment.
Provision `/mnt/var/lib/sops/shared.yaml` with mode 0600, encrypted to both
Elliott's existing GPG recipient and the installed machine's SSH host key.
Preserve that host key under `/mnt/etc/ssh` during installation. See
`../studiobox/README.md` for the shared secret schema and provisioning model.
