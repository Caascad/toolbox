{ fetchzip
, lib
, sources
, makeWrapper
, plugins
, nixpkgs ? sources.nixpkgs
}:
let 
  pkgs = import nixpkgs {};
in
rec {

  packages = builtins.attrValues plugins;
  kubectl-all = pkgs.kubectl.overrideAttrs (old: {
    buildInputs = [ makeWrapper ];
    installPhase = old.installPhase + ''
      wrapProgram "$out/bin/kubectl" --prefix PATH ":" ${lib.makeBinPath(packages)}
    '';
  });
}
