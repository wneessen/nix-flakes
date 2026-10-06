{
  description = "hcloud - Hetzner Cloud CLI (prebuilt release binaries)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      sources = builtins.fromJSON (builtins.readFile ./sources.json);
      systems = builtins.attrNames sources.platforms;
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      mkHcloud = pkgs: pkgs.callPackage ./package.nix { inherit sources; };
    in
    {
      packages = forAllSystems (pkgs: rec {
        hcloud = mkHcloud pkgs;
        default = hcloud;
      });

      overlays.default = final: _prev: { hcloud = mkHcloud final; };

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
