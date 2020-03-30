{ stdenv
, makeWrapper
, coreutils
, jq
, utillinux
}:

stdenv.mkDerivation {
  pname = "toolbox";
  version = "1.2";

  buildInputs = [ makeWrapper ];
  passAsFile = [ "buildCommand" ];
  buildCommand = ''
    mkdir -p $out/bin
    cp ${./toolbox.sh} $out/bin/toolbox
    chmod +x $out/bin/toolbox
    wrapProgram $out/bin/toolbox --prefix PATH ":" ${coreutils}/bin:${jq}/bin:${utillinux}/bin
  '';
}
