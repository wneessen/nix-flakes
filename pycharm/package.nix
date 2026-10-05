{
  lib,
  stdenv,
  fetchurl,
  jetbrains,
}:

let
  sources = lib.importJSON ./sources.json;
  system = stdenv.hostPlatform.system;
  entry = sources.systems.${system} or (throw "pycharm: unsupported system: ${system}");
in
# PyCharm is unified since 2025.1 (Community + Professional merged); in
# nixpkgs this is `jetbrains.pycharm` (formerly `pycharm-professional`).
jetbrains.pycharm.overrideAttrs (old: {
  version = sources.version;

  # the builder derives `name` from its own version arg, which overrideAttrs
  # can't reach — pin it so the store path shows the right version
  name = "pycharm-${sources.version}";

  src = fetchurl { inherit (entry) url hash; };

  passthru = (old.passthru or { }) // {
    buildNumber = sources.buildNumber;
  };

  meta = (old.meta or { }) // { maintainers = [ ]; };
})
