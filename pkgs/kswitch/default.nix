{ stdenv
, runCommand
, makeWrapper
, kubectl
, jq
, coreutils
}:

stdenv.mkDerivation {
  pname = "kswitch";
  version = "1.3";

  buildInputs = [ makeWrapper ];
  passAsFile = [ "buildCommand" ];
  buildCommand = ''
    mkdir -p $out/bin $out/share/bash-completion/completions
    cp ${./kswitch.sh} $out/bin/kswitch
    chmod +x $out/bin/kswitch
    bash $out/bin/kswitch bash-completions >  $out/share/bash-completion/completions/kswitch

    wrapProgram $out/bin/kswitch --prefix PATH ":" ${kubectl}/bin:${jq}/bin:${coreutils}/bin
  '';

  meta = with stdenv.lib; {
    description = "Caascad K8S cluster tunneling through bastions";
    homepage = "https://github.com/Caascad/toolbox";
    license = licenses.mit;
    maintainers = with maintainers; [ eonpatapon ];
  };

}
