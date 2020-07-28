{ lib
, makeWrapper
, plugins
, kubectl
}:

kubectl.overrideAttrs (old: {
    buildInputs = [ makeWrapper ];
    installPhase = old.installPhase + ''
      wrapProgram "$out/bin/kubectl" --prefix PATH ":" ${lib.makeBinPath (builtins.attrValues plugins)}
    '';
})
