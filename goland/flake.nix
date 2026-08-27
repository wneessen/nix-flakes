{
  description = "JetBrains GoLand, pinned to a version of my choosing";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # GoLand is unfree, so allowUnfree is set *here*. That way consumers
      # importing packages.<system>.default don't need to configure anything.
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          goland = pkgs.callPackage ./package.nix { };
        in
        {
          inherit goland;
          default = goland;
          update = pkgs.callPackage ./update.nix { };
        }
      );

      # optional, but handy if you ever want it in an overlay-based config
      overlays.default = final: prev: {
        goland-latest = final.callPackage ./package.nix { };
      };

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.goland}/bin/goland";
        };
        update = {
          type = "app";
          program = "${self.packages.${system}.update}/bin/update-goland";
        };
      });

      devShells = forAllSystems (
        system:
        let pkgs = pkgsFor system;
        in {
          default = pkgs.mkShell { packages = [ pkgs.curl pkgs.jq pkgs.nixfmt-rfc-style ]; };
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-rfc-style);
    };
}

