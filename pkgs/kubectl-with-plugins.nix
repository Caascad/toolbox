{ lib
, stdenv
, makeWrapper
, plugins
, kubectl
, installShellFiles
}:

stdenv.mkDerivation {
  pname = "kubectl-with-plugins";
  version = kubectl.version;
  buildInputs = [ makeWrapper installShellFiles ];
  unpackPhase = ":";
  installPhase = kubectl.installPhase + ''
    wrapProgram "$out/bin/kubectl" --prefix PATH ":" ${lib.makeBinPath (builtins.attrValues plugins)}
  '';
}
