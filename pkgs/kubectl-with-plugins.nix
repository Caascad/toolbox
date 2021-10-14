{ lib
, makeWrapper
, plugins
, kubectl
}:

kubectl.overrideAttrs (old: {
  pname = "kubectl-with-plugins";
  version = kubectl.version;
  buildInputs = [ makeWrapper ];
  installPhase = old.installPhase + ''
    wrapProgram "$out/bin/kubectl" --prefix PATH ":" ${lib.makeBinPath (builtins.attrValues plugins)}
  '';
})
