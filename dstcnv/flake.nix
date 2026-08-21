{
  description = "dstcnv - converts DST compressed DSDIFF files into uncompressed DSDIFF";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        dstcnv = pkgs.stdenv.mkDerivation rec {
          pname = "dstcnv";
          version = "0-unstable-2018-12-14";

          src = pkgs.fetchFromGitHub {
            owner = "ntaka777";
            repo = "dstcnv";
            rev = "master";
            hash = "sha256-lBM1+lxeJWry/DV6uh/aNM3gcqYT+VlfvLB/dRerR1w=";
          };

          # Upstream Makefile hardcodes `CC = gcc`; overriding on the command
          # line also propagates into the recursive make in libdstdec/.
          makeFlags = [ "CC=${pkgs.stdenv.cc.targetPrefix}cc" ];

          # Don't set CFLAGS= directly: the Makefile needs its own -I libdstdec.
          env.NIX_CFLAGS_COMPILE = "-D_FILE_OFFSET_BITS=64";

          enableParallelBuilding = true;

          # Upstream has only `all` and `clean` targets, no `install`.
          installPhase = ''
            runHook preInstall
            install -Dm755 dstcnv "$out/bin/dstcnv"
            runHook postInstall
          '';

          doInstallCheck = true;
          installCheckPhase = ''
            "$out/bin/dstcnv" -V
          '';

          meta = with pkgs.lib; {
            description = "Converts DST compressed DSDIFF files into uncompressed DSDIFF files";
            homepage = "https://github.com/ntaka777/dstcnv";
            license = licenses.gpl2Only;
            platforms = platforms.unix;
            mainProgram = "dstcnv";
          };
        };
      in
      {
        packages.dstcnv = dstcnv;
        packages.default = dstcnv;

        apps.dstcnv = flake-utils.lib.mkApp { drv = dstcnv; };
        apps.default = flake-utils.lib.mkApp { drv = dstcnv; };
      });
}

