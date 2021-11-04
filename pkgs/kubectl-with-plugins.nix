{ lib
, stdenv
, makeWrapper
, plugins
, kubectl
}:

stdenv.mkDerivation {
  pname = "kubectl-with-plugins";
  version = kubectl.version;
  buildInputs = [ makeWrapper ];
  unpackPhase = ":";
  installPhase = ''
    mkdir -p $out/bin
    ln -s ${kubectl}/bin/kubectl $out/bin
    wrapProgram "$out/bin/kubectl" --prefix PATH ":" ${lib.makeBinPath (builtins.attrValues plugins)}
  '';
}
