{ stdenv
, lib
, runCommand
, makeWrapper
, kubectl
, jq
, coreutils
, vault
, awscli
, curl
, findutils
}:

stdenv.mkDerivation rec {
  pname = "kswitch";
  version = "1.8.0";

  buildInputs = [ makeWrapper ];
  passAsFile = [ "buildCommand" ];
  buildCommand = ''
    mkdir -p $out/bin $out/share/bash-completion/completions
    cp ${./kswitch.sh} $out/bin/kswitch
    chmod +x $out/bin/kswitch
    bash $out/bin/kswitch bash-completions >  $out/share/bash-completion/completions/kswitch

    substituteInPlace $out/bin/kswitch --replace KSWITCH_VERSION ${version}
    wrapProgram $out/bin/kswitch --prefix PATH ":" ${lib.makeBinPath [ kubectl jq coreutils vault awscli curl findutils ]}
  '';

  meta = with lib; {
    description = "Caascad K8S cluster tunneling through bastions";
    homepage = "https://github.com/Caascad/toolbox";
    license = licenses.mit;
    maintainers = with maintainers; [ eonpatapon ];
  };

}
