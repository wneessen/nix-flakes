{ writeShellApplication, curl, jq, nix, coreutils, gnused, gawk }:

writeShellApplication {
  name = "update-pycharm";
  runtimeInputs = [ curl jq nix coreutils gnused gawk ];
  text = builtins.readFile ./update.sh;
}
