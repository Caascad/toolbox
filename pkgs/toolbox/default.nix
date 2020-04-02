{ stdenv
, makeWrapper
, coreutils
, jq
, utillinux
}:

stdenv.mkDerivation {
  pname = "toolbox";
  version = "1.4";

  buildInputs = [ makeWrapper ];
  passAsFile = [ "buildCommand" ];
  buildCommand = ''
    mkdir -p $out/bin $out/share/bash-completion/completions
    cp ${./toolbox.sh} $out/bin/toolbox
    chmod +x $out/bin/toolbox
    bash $out/bin/toolbox completions >  $out/share/bash-completion/completions/toolbox

    wrapProgram $out/bin/toolbox --prefix PATH ":" ${coreutils}/bin:${jq}/bin:${utillinux}/bin
  '';
}
