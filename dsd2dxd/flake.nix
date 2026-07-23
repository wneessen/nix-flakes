{
  description = "dsd2dxd - DSD to DXD/PCM converter (prebuilt binary release)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        dsd2dxd = pkgs.stdenv.mkDerivation rec {
          pname = "dsd2dxd";
          version = "2.7.0";

          src = pkgs.fetchurl {
            url = "https://github.com/clone206/dsd2dxd/releases/download/v${version}/x86_64-unknown-linux-gnu.zip";
            hash = "sha256-5xf9RsKPdmEP4KEQQgXIs0E0UdNMX4GiqeYyOwkMkTk=";
          };

          nativeBuildInputs = [
            pkgs.unzip
            pkgs.autoPatchelfHook
          ];

          buildInputs = [
            pkgs.stdenv.cc.cc.lib
          ];

          sourceRoot = ".";

          installPhase = ''
            runHook preInstall
            install -Dm755 x86_64-unknown-linux-gnu/dsd2dxd    "$out/bin/dsd2dxd"
            install -Dm755 x86_64-unknown-linux-gnu/dsd_levels "$out/bin/dsd_levels"
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Converts DSD audio (DSF/DFF) to DXD/PCM";
            homepage = "https://github.com/clone206/dsd2dxd";
            license = licenses.mit; # adjust if upstream differs
            platforms = [ "x86_64-linux" ];
            sourceProvenance = [ sourceTypes.binaryNativeCode ];
            mainProgram = "dsd2dxd";
          };
        };
      in
      {
        packages.dsd2dxd = dsd2dxd;
        packages.default = dsd2dxd;

        apps.dsd2dxd = flake-utils.lib.mkApp { drv = dsd2dxd; };
        apps.default = flake-utils.lib.mkApp { drv = dsd2dxd; };
      });
}

