{ stdenv
, lib
, runCommand
, makeWrapper
, jq
, curl
}:

stdenv.mkDerivation rec {
  pname = "getzones";
  version = "0.0.1";

  buildInputs = [ makeWrapper ];
  passAsFile = [ "buildCommand" ];
  buildCommand = ''
    mkdir -p $out/bin $out/share/bash-completion/completions
    cp ${./getzones.sh} $out/bin/getzones
    chmod +x $out/bin/getzones
    bash $out/bin/getzones bash-completions >  $out/share/bash-completion/completions/getzones

    substituteInPlace $out/bin/getzones --replace GETZONES_VERSION ${version}
    wrapProgram $out/bin/getzones --prefix PATH ":" ${lib.makeBinPath [ jq curl ]}
  '';

  meta = with stdenv.lib; {
    description = "Get OCB & Client zones given a parent zone name";
    homepage = "https://github.com/Caascad/toolbox";
    license = licenses.mit;
    maintainers = with maintainers; [ winael ];
  };

}
