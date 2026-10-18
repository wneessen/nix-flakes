{
  description = "Waterfox browser (official Linux x64 binaries)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = rec {
        waterfox-bin-unwrapped = pkgs.callPackage ./package.nix { };
        waterfox-bin = pkgs.wrapFirefox waterfox-bin-unwrapped { pname = "waterfox-bin"; };
        default = waterfox-bin;
      };
    };
}

