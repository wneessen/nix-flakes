{
  lib,
  stdenv,
  fetchurl,
  jetbrains,
}:

let
  sources = lib.importJSON ./sources.json;
  system = stdenv.hostPlatform.system;
  entry = sources.systems.${system} or (throw "goland: unsupported system: ${system}");
in
jetbrains.goland.overrideAttrs (old: {
  version = sources.version;

  # the builder derives `name` from its own version arg, which overrideAttrs
  # can't reach — pin it so the store path shows the right version
  name = "goland-${sources.version}";

  src = fetchurl { inherit (entry) url hash; };

  passthru = (old.passthru or { }) // {
    buildNumber = sources.buildNumber;
  };

  meta = (old.meta or { }) // { maintainers = [ ]; };
})

