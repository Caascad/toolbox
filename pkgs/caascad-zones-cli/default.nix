{ stdenv
, lib
, runCommand
, makeWrapper
, jq
, curl
}:

stdenv.mkDerivation rec {
  pname = "caascad-zones-cli";
  version = "0.0.1";

  buildInputs = [ makeWrapper ];
  passAsFile = [ "buildCommand" ];
  buildCommand = ''
    mkdir -p $out/bin $out/share/bash-completion/completions
    cp ${./caascad-zones-cli.sh} $out/bin/caascad-zones-cli
    chmod +x $out/bin/caascad-zones-cli
    bash $out/bin/caascad-zones-cli bash-completions >  $out/share/bash-completion/completions/aascad-zones-cli

    substituteInPlace $out/bin/caascad-zones-cli --replace GETZONES_VERSION ${version}
    wrapProgram $out/bin/caascad-zones-cli --prefix PATH ":" ${lib.makeBinPath [ jq curl ]}
  '';

  meta = with stdenv.lib; {
    description = "Get OCB & Client zones given a parent zone name";
    homepage = "https://github.com/Caascad/toolbox";
    license = licenses.mit;
    maintainers = with maintainers; [ winael ];
  };

}
