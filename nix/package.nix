{ lib
, stdenvNoCC
, python3
, makeWrapper
, quickshell
}:

# waycal is mostly QML + a stdlib-only Python adapter. The adapter shells out to
# the `gog` CLI at runtime (expected on PATH), so it has no Python dependencies.
let
  pythonEnv = python3;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "waycal";
  version = "0.1.0";

  src = lib.cleanSource ../.;

  nativeBuildInputs = [ makeWrapper ];

  # Pure copy + wrapper install; nothing to compile.
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/waycal
    cp -r frontend backend $out/share/waycal/

    makeWrapper ${pythonEnv}/bin/python3 $out/bin/waycal-fetch \
      --add-flags "$out/share/waycal/backend/waycal_fetch.py"

    runHook postInstall
  '';

  passthru = {
    inherit quickshell;
    # Convenience: the frontend dir to point `qs -p` at, or to symlink into XDG config.
    frontendPath = "${finalAttrs.finalPackage}/share/waycal/frontend";
  };

  meta = {
    description = "Calendar/Mail/Tasks Wayland widgets driven by the gog CLI, rendered with Quickshell";
    homepage = "https://github.com/olafkfreund/waycal";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = [ ];
    mainProgram = "waycal-fetch";
  };
})
