#!/usr/bin/env bash
# Run as your normal user so SOPS can use your YubiKey/GPG agent.
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
secrets_file="$repo_dir/secrets/shared.yaml"
work_dir=/run/studiobox

case "${1:-}" in
  disk-key)
    sudo install -d -m 0700 -o "$(id -u)" "$work_dir"
    umask 077
    key_tmp=$(mktemp "$work_dir/luks-password.XXXXXX")
    trap 'rm -f -- "$key_tmp"' EXIT
    sops decrypt --extract '["luks_password"]' "$secrets_file" > "$key_tmp"
    test -s "$key_tmp"
    mv -- "$key_tmp" "$work_dir/luks-password"
    ;;
  deploy)
    target_root=${2:-/mnt}
    test -d "$target_root/etc"
    host_key="$target_root/etc/ssh/ssh_host_ed25519_key"
    sudo install -d -m 0755 "$target_root/etc/ssh"
    if ! sudo test -f "$host_key"; then
      sudo ssh-keygen -q -t ed25519 -N '' -f "$host_key"
    fi
    recipient=$(sudo cat "$host_key.pub" | ssh-to-age)
    sudo install -d -m 0700 -o "$(id -u)" "$work_dir"
    umask 077
    encrypted_tmp=$(mktemp "$work_dir/encrypted.XXXXXX")
    trap 'rm -f -- "$encrypted_tmp"' EXIT
    # Plaintext travels only through the pipe, never through the Nix store.
    sops decrypt "$secrets_file" |
      (cd / && sops encrypt --input-type yaml --output-type yaml \
        --age "$recipient" --pgp C8D26C04DD1E397A6926633080015B87EFAB63A4 \
        /dev/stdin) > "$encrypted_tmp"
    test -s "$encrypted_tmp"
    sudo install -d -m 0700 "$target_root/var/lib/sops"
    sudo install -m 0600 "$encrypted_tmp" "$target_root/var/lib/sops/shared.yaml"
    ;;
  *)
    echo 'Usage: prepare-secrets.sh disk-key | deploy [target-root]' >&2
    exit 2
    ;;
esac
