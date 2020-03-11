{ stdenv
, runCommand
, makeWrapper
, kubectl
, jq
}:

stdenv.mkDerivation {
  pname = "kswitch";
  version = "1.1";

  buildInputs = [ makeWrapper ];
  passAsFile = [ "buildCommand" ];
  buildCommand = ''
    mkdir -p $out/bin
    cp ${./kswitch.sh} $out/bin/kswitch
    chmod +x $out/bin/kswitch
    wrapProgram $out/bin/kswitch --prefix PATH ":" ${kubectl}/bin:${jq}/bin
  '';

  meta = with stdenv.lib; {
    description = "Caascad K8S cluster tunneling through bastions";
    homepage = "https://github.com/Caascad/";
    license = licenses.mit;
    maintainers = with maintainers; [ eonpatapon ];
  };

}
