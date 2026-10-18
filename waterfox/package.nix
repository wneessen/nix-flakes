{
  lib,
  stdenv,
  fetchurl,
  wrapGAppsHook3,
  autoPatchelfHook,
  patchelfUnstable,
  alsa-lib,
  curl,
  dbus-glib,
  gtk3,
  libxtst,
  libva,
  pciutils,
  pipewire,
  adwaita-icon-theme,
  writeText,
}:

let
  version = "6.7.6";
  libName = "waterfox-bin-${version}";

  policiesJson = writeText "waterfox-policies.json" (
    builtins.toJSON { policies.DisableAppUpdate = true; }
  );
in
stdenv.mkDerivation {
  pname = "waterfox-bin-unwrapped";
  inherit version;

  src = fetchurl {
    url = "https://cdn.waterfox.com/waterfox/releases/${version}/Linux_x86_64/waterfox-${version}.tar.bz2";
    hash = "sha256-kxY7aDUaWKTWZFchm5Xvhv5wZqZSTYG7bKvXR956kFY=";
  };

  nativeBuildInputs = [
    wrapGAppsHook3
    autoPatchelfHook
    patchelfUnstable
  ];

  buildInputs = [
    gtk3
    adwaita-icon-theme
    alsa-lib
    dbus-glib
    libxtst
  ];

  runtimeDependencies = [
    curl
    pciutils
    libva.out
  ];

  appendRunpaths = [ "${pipewire}/lib" ];

  # Same as firefox-bin (Mozilla "relrhack")
  patchelfFlags = [ "--no-clobber-old-sections" ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/${libName}" "$out/bin"
    cp -r * "$out/lib/${libName}"
    ln -s "$out/lib/${libName}/waterfox" "$out/bin/waterfox"

    mkdir -p "$out/lib/${libName}/distribution"
    ln -s ${policiesJson} "$out/lib/${libName}/distribution/policies.json"

    runHook postInstall
  '';

  # Needed by wrapFirefox
  passthru = {
    applicationName = "Waterfox";
    binaryName = "waterfox";
    inherit libName;
    withFFmpeg = true;
    withGSSAPI = true;
    inherit gtk3;
  };

  meta = {
    description = "Waterfox web browser (binary package)";
    homepage = "https://www.waterfox.com/";
    license = lib.licenses.mpl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "waterfox";
  };
}

