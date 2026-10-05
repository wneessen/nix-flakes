# Usage (from inside the pycharm/ directory):
#   nix run .#update              # latest stable
#   nix run .#update -- 2026.3.1  # specific version
#   CHANNEL=eap nix run .#update  # latest EAP
# Override target with SOURCES_JSON=/abs/path/sources.json
# Override product code with PRODUCT_CODE=... (default: PCP, unified PyCharm)

out="${SOURCES_JSON:-./sources.json}"
channel="${CHANNEL:-release}"
code="${PRODUCT_CODE:-PCP}"
want="${1:-}"

api="https://data.services.jetbrains.com/products/releases?code=${code}&type=${channel}"

# the response is keyed by product code; take the first key so we don't
# depend on the exact spelling JetBrains returns
if [[ -z "$want" ]]; then
  release="$(curl -fsSL "${api}&latest=true" | jq -c 'to_entries[0].value[0]')"
else
  release="$(curl -fsSL "$api" |
    jq -c --arg v "$want" \
      '[to_entries[0].value[] | select(.version == $v or (.downloads.linux.link | contains($v)))] | first')"
fi

if [[ -z "$release" || "$release" == "null" ]]; then
  echo "update-pycharm: no ${channel} release found${want:+ for $want}" >&2
  exit 1
fi

build="$(jq -r '.build' <<<"$release")"

to_sri() {
  local hex
  hex="$(awk '{print $1}')"
  nix hash convert --hash-algo sha256 --to sri "$hex" 2>/dev/null \
    || nix hash to-sri --type sha256 "$hex"
}

fetch_entry() {
  local key="$1" url csum hash
  url="$(jq -r --arg k "$key" '.downloads[$k].link // empty' <<<"$release")"
  [[ -n "$url" ]] || { echo "update-pycharm: no download for '$key'" >&2; return 1; }
  csum="$(jq -r --arg k "$key" '.downloads[$k].checksumLink // empty' <<<"$release")"
  [[ -n "$csum" ]] || csum="${url}.sha256"
  hash="$(curl -fsSL "$csum" | to_sri)"
  jq -n --arg url "$url" --arg hash "$hash" '{url: $url, hash: $hash}'
}

x86="$(fetch_entry linux)"
arm="$(fetch_entry linuxARM64)"
mac="$(fetch_entry macM1)"

# the API's .version is 3-component (2026.2.2); the artifact may be 4 (2026.2.2.1)
version="$(jq -r '.url' <<<"$x86" | sed -E 's|.*/pycharm-(.*)\.tar\.gz|\1|')"

jq -n \
  --arg version "$version" \
  --arg buildNumber "$build" \
  --argjson x "$x86" --argjson a "$arm" --argjson m "$mac" \
  '{version: $version, buildNumber: $buildNumber,
    systems: {"x86_64-linux": $x, "aarch64-linux": $a, "aarch64-darwin": $m}}' \
  > "$out"

echo "update-pycharm: wrote $out (version $version, build $build)"
