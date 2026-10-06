{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  versionCheckHook,
  sources,
}:

let
  inherit (stdenvNoCC.hostPlatform) system;
  platform = sources.platforms.${system} or (throw "hcloud: unsupported system ${system}");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hcloud";
  inherit (sources) version;

  src = fetchurl {
    url = "https://github.com/hetznercloud/cli/releases/download/v${finalAttrs.version}/hcloud-${platform.asset}.tar.gz";
    inherit (platform) hash;
  };

  # The release tarball has no top-level directory
  sourceRoot = ".";

  nativeBuildInputs = [ installShellFiles ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 hcloud $out/bin/hcloud
    runHook postInstall
  '';

  # Generate completions by running the binary (only possible when not cross-compiling)
  postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
    for shell in bash fish zsh; do
      installShellCompletion --cmd hcloud --$shell <($out/bin/hcloud completion $shell)
    done
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "version";

  meta = {
    description = "Command-line interface for Hetzner Cloud";
    homepage = "https://github.com/hetznercloud/cli";
    changelog = "https://github.com/hetznercloud/cli/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "hcloud";
    platforms = builtins.attrNames sources.platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
