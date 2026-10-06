#!/usr/bin/env bash
# Update sources.json to the latest (or a given) hcloud release.
# Usage: ./update.sh [version]   e.g. ./update.sh 1.70.0
# Requires: curl, jq, nix (>= 2.19 for `nix hash convert`)
set -euo pipefail

cd "$(dirname "$0")"
repo="https://github.com/hetznercloud/cli"

if [[ $# -ge 1 ]]; then
  version="${1#v}"
else
  # Follow the /releases/latest redirect instead of using the rate-limited API
  version="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$repo/releases/latest")"
  version="${version##*/v}"
fi

current="$(jq -r .version sources.json)"
if [[ "$version" == "$current" ]]; then
  echo "hcloud is already at $version"
  exit 0
fi

echo "Updating hcloud: $current -> $version"
checksums="$(curl -fsSL "$repo/releases/download/v$version/checksums.txt")"

tmp="$(mktemp)"
cp sources.json "$tmp"
jq --arg v "$version" '.version = $v' "$tmp" > sources.json

for system in $(jq -r '.platforms | keys[]' sources.json); do
  asset="$(jq -r --arg s "$system" '.platforms[$s].asset' sources.json)"
  hex="$(awk -v f="hcloud-$asset.tar.gz" '$2 == f { print $1 }' <<<"$checksums")"
  if [[ -z "$hex" ]]; then
    echo "No checksum found for hcloud-$asset.tar.gz" >&2
    cp "$tmp" sources.json
    exit 1
  fi
  sri="$(nix hash convert --hash-algo sha256 --to sri "$hex")"
  jq --arg s "$system" --arg h "$sri" '.platforms[$s].hash = $h' sources.json > "$tmp.new"
  mv "$tmp.new" sources.json
  echo "  $system: $sri"
done

rm -f "$tmp"
echo "Done. Test with: nix build .#hcloud && ./result/bin/hcloud version"
