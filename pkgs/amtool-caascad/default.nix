{ stdenv
, lib
, runCommand
, makeWrapper
, amtool
, vault
}:

stdenv.mkDerivation rec {
  pname = "amtool-caascad";
  version = "1.0.1";

  buildInputs = [ makeWrapper ];

  dontBuild = true;
  dontConfigure = true;
  unpackPhase = ":";
  installPhase = ''
    mkdir -p $out/bin
    cp ${./amtool-caascad.sh} $out/bin/amtool-caascad
    chmod +x $out/bin/amtool-caascad

    substituteInPlace $out/bin/amtool-caascad --replace AMTOOL_CAASCAD_VERSION ${version}
    wrapProgram $out/bin/amtool-caascad --prefix PATH ":" ${lib.makeBinPath [ vault amtool ]}
  '';

  meta = with lib; {
    description = "Caascad amtool wrapper";
    homepage = "https://github.com/Caascad/toolbox";
    license = licenses.mit;
    maintainers = with maintainers; [ "ngc104" ];
  };

}
