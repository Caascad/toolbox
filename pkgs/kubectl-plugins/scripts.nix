{ stdenv
, fetchzip
, source
, cmdName
, outCmdName ? cmdName
, scriptPatches ? []
}:

stdenv.mkDerivation rec {
  pname = outCmdName;
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };
  patches = scriptPatches;
  installPhase = ''
    install -m755 -D ./${cmdName} $out/bin/${outCmdName}
  '';

  meta = with stdenv.lib; {
    description = source.description;
    homepage = source.homepage;
  };
}

