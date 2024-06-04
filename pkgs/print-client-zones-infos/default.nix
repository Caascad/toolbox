{ stdenv
, lib
, runCommand
, makeWrapper
}:

stdenv.mkDerivation rec {
  pname = "print-client-zones-infos";
  version = "1.2.0";

  buildInputs = [ makeWrapper ];

  dontBuild = true;
  dontConfigure = true;
  unpackPhase = ":";
  installPhase = ''
    mkdir -p $out/bin
    cp ${./print-client-zones-infos.sh} $out/bin/print-client-zones-infos
    chmod +x $out/bin/print-client-zones-infos

    substituteInPlace $out/bin/print-client-zones-infos --replace PRINT_CLIENT_ZONES_INFOS_VERSION ${version}
    wrapProgram $out/bin/print-client-zones-infos --prefix PATH ":" ${lib.makeBinPath [ ]}
  '';

  meta = with lib; {
    description = "Print NGOT zones infos for a given client/contract";
    homepage = "https://github.com/Caascad/toolbox";
    license = licenses.mit;
    maintainers = with maintainers; [ "ngc104" ];
  };

}
