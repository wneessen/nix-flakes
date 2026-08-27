{ writeShellApplication, curl, jq, nix, coreutils, gnused, gawk }:

writeShellApplication {
  name = "update-goland";
  runtimeInputs = [ curl jq nix coreutils gnused gawk ];
  text = builtins.readFile ./update.sh;
}

