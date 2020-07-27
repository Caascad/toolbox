{ lib
, makeWrapper
, plugins
, kubectl
}:
rec {

  packages = (builtins.attrValues plugins);
  kubectl-all = kubectl.overrideAttrs (old: {
    buildInputs = [ makeWrapper ];
    installPhase = old.installPhase + ''
      wrapProgram "$out/bin/kubectl" --prefix PATH ":" ${lib.makeBinPath(packages)}
    '';
  });
}
