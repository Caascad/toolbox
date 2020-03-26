{ stdenv
, runCommand
, makeWrapper
, kubectl
, jq
, coreutils
}:

stdenv.mkDerivation {
  pname = "kswitch";
  version = "1.2";

  buildInputs = [ makeWrapper ];
  passAsFile = [ "buildCommand" ];
  buildCommand = ''
    mkdir -p $out/bin
    cp ${./kswitch.sh} $out/bin/kswitch
    chmod +x $out/bin/kswitch
    wrapProgram $out/bin/kswitch --prefix PATH ":" ${kubectl}/bin:${jq}/bin:${coreutils}/bin
  '';

  meta = with stdenv.lib; {
    description = "Caascad K8S cluster tunneling through bastions";
    homepage = "https://github.com/Caascad/toolbox";
    license = licenses.mit;
    maintainers = with maintainers; [ eonpatapon ];
  };

}
