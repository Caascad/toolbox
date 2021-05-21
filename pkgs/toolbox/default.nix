{ stdenv
, lib
, makeWrapper
, coreutils
, jq
, utillinux
, gnused
}:

stdenv.mkDerivation {
  pname = "toolbox";
  version = "2.1.0";

  buildInputs = [ makeWrapper ];
  passAsFile = [ "buildCommand" ];
  buildCommand = ''
    mkdir -p $out/bin $out/share/bash-completion/completions
    cp ${./toolbox.sh} $out/bin/toolbox
    chmod +x $out/bin/toolbox
    bash $out/bin/toolbox completions >  $out/share/bash-completion/completions/toolbox

    wrapProgram $out/bin/toolbox --prefix PATH ":" ${coreutils}/bin:${jq}/bin:${utillinux}/bin:${gnused}/bin
  '';

  meta = with lib; {
    description = "Caascad toolbox";
    homepage = "https://github.com/Caascad/toolbox";
    license = licenses.mit;
    maintainers = with maintainers; [ eonpatapon ];
  };

}
