{ stdenv
, runCommand
, makeWrapper
, kubectl
, jq
}:

runCommand "kswitch" rec {
  name = "kswitch-${version}";
  version = "1.0";
  buildInputs = [ makeWrapper ];
  meta = with stdenv.lib; {
    description = "Caascad K8S cluster tunneling through bastions";
    homepage = "https://github.com/Caascad/";
    license = licenses.mit;
    maintainers = with maintainers; [ eonpatapon ];
  };
} ''
  mkdir -p $out/bin
  cp ${./kswitch.sh} $out/bin/kswitch
  chmod +x $out/bin/kswitch
  wrapProgram $out/bin/kswitch --prefix PATH ":" ${kubectl}/bin:${jq}/bin
''
