{
  description = "sacd_extract - patched prebuilt Linux binary";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # older nixpkgs that still ships libxml2 2.13 (real libxml2.so.2 with version nodes)
  inputs.nixpkgs-old.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs, nixpkgs-old }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      pkgsOld = import nixpkgs-old { inherit system; };

      sacd_extract = pkgs.stdenv.mkDerivation {
        pname = "sacd_extract";
        version = "0.3.9.3-173";

        src = pkgs.fetchzip {
          url = "https://raw.githubusercontent.com/wneessen/nix-flakes/refs/heads/main/binaries/sacd_extract-0.3.9.3-173-linux.zip";
          hash = "sha256-zPtqbTBi3x1vEqK/Crz9BI2M25Iorr7z3Oj1YnTg11o=";
          stripRoot = false;
        };

        nativeBuildInputs = [ pkgs.autoPatchelfHook ];

        buildInputs = [
          pkgs.stdenv.cc.cc.lib   # libstdc++ / libgcc_s
          pkgsOld.libxml2         # 2.13 -> real libxml2.so.2 with version symbols
          pkgs.zlib
          pkgs.libusb1            # direct SACD disc reading
        ];

        dontBuild = true;
        dontConfigure = true;

        installPhase = ''
          runHook preInstall
          bin=$(find . -type f -name 'sacd_extract' | head -n1)
          install -Dm755 "$bin" "$out/bin/sacd_extract"
          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "Extractor for Super Audio CD ISO/DSF/DFF files";
          platforms = [ "x86_64-linux" ];
          sourceProvenance = [ sourceTypes.binaryNativeCode ];
          license = licenses.gpl2Plus;
        };
      };
    in {
      packages.${system} = {
        default = sacd_extract;
        sacd_extract = sacd_extract;
      };

      apps.${system}.default = {
        type = "app";
        program = "${sacd_extract}/bin/sacd_extract";
      };
    };
}

