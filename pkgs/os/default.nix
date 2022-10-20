{ pkgs
, openstackclient
, vault
, curl
, jq
, sedutil
}:

with pkgs;

stdenv.mkDerivation rec {
  pname = "os";
  version = "1.6.0";

  buildInputs = [ makeWrapper ];
  passAsFile = [ "buildCommand" ];
  buildCommand = ''
    mkdir -p $out/bin
    cp ${./os.sh} $out/bin/os
    chmod +x $out/bin/os

    wrapProgram $out/bin/os --prefix PATH ":" ${lib.makeBinPath [ openstackclient vault curl jq ]}
  '';

  meta = with lib; {
    description = "Thin wrapper around openstackclient";
    homepage = "https://github.com/Caascad/toolbox";
    license = licenses.mit;
    maintainers = with maintainers; [ "Benjile" ];
  };

}
