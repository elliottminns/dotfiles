#!/bin/bash
# One-time setup for amaterasu. Re-running preserves the existing identity.
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
umask 077

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo /bin/bash extra/services/setup-kanata-signing.sh" >&2
  exit 1
fi
if [[ $(scutil --get LocalHostName) != amaterasu ]]; then
  echo "This setup is scoped to amaterasu." >&2
  exit 1
fi

identity='amaterasu Kanata Signing'
keychain=/Library/Keychains/System.keychain
binary=/usr/local/libexec/nix-darwin/kanata/kanata
[[ -x "$binary" ]] || { echo "Installed Kanata binary not found." >&2; exit 1; }

workdir=$(mktemp -d /private/tmp/kanata-signing.XXXXXX)
stage=''
trap 'rm -rf "$workdir"; if [[ -n "$stage" ]]; then rm -f "$stage"; fi' EXIT

if ! security find-certificate -c "$identity" -p "$keychain" > "$workdir/cert.pem"; then
  cat > "$workdir/openssl.cnf" <<'EOF'
[req]
prompt = no
distinguished_name = subject
x509_extensions = signing
[subject]
CN = amaterasu Kanata Signing
[signing]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
subjectKeyIdentifier = hash
EOF
  # Temporary key material is root-only and removed on exit. The imported key
  # is non-extractable and permits codesign access, not arbitrary applications.
  openssl req -new -x509 -newkey rsa:3072 -nodes -sha256 -days 3650 \
    -config "$workdir/openssl.cnf" \
    -keyout "$workdir/key.pem" -out "$workdir/cert.pem"
  # macOS rejects LibreSSL PKCS#12 files with an empty password (-25293).
  openssl rand -hex 32 > "$workdir/password"
  read -r p12Password < "$workdir/password"
  openssl pkcs12 -export -name "$identity" \
    -inkey "$workdir/key.pem" -in "$workdir/cert.pem" \
    -out "$workdir/identity.p12" -passout "file:$workdir/password"
  security import "$workdir/identity.p12" -k "$keychain" \
    -f pkcs12 -P "$p12Password" -x -T /usr/bin/codesign
  unset p12Password
  rm -f "$workdir/key.pem" "$workdir/identity.p12" "$workdir/password"
fi

# Trust is restricted to code signing; this is not a TLS trust anchor.
security add-trusted-cert -d -r trustRoot -p codeSign \
  -k "$keychain" "$workdir/cert.pem"
fingerprint=$(openssl x509 -in "$workdir/cert.pem" -noout -fingerprint -sha1 | sed 's/.*=//; s/://g')
if ! security find-identity -v -p codesigning "$keychain" | grep -Fq "$fingerprint"; then
  echo "The existing certificate has no usable private key. It was not replaced." >&2
  exit 1
fi

# Match the Nix activation hook. Never modify the running executable in place.
stage=$(mktemp "${binary%/*}/.kanata.XXXXXX")
install -m 0755 "$binary" "$stage"
codesign --force --timestamp=none --keychain "$keychain" \
  --sign "$fingerprint" --identifier org.nixos.kanata "$stage"
codesign --verify --strict \
  -R "=identifier \"org.nixos.kanata\" and certificate leaf = H\"$fingerprint\"" "$stage"
codesign -d -r- "$stage"
if ! cmp -s "$stage" "$binary"; then
  mv -f "$stage" "$binary"
fi
launchctl kickstart -k system/org.nixos.kanata-internal
echo "Signing configured. Re-add Kanata in Input Monitoring and Accessibility once."
