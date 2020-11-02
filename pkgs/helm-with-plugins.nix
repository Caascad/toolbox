{ pkgs
, stdenv
, lib
, makeWrapper
, plugins
, kubernetes-helm
}:

let

  installPlugin = name: plugin: ''
    mkdir -p $out/${plugin.pname}
    ln -s ${plugin}/bin $out/${plugin.pname}
    cp ${plugin.src}/plugin.yaml $out/${plugin.pname}
  '';

  helm-plugins = stdenv.mkDerivation {
    name = "helm-plugins";
    phases = [ "installPhase" ];
    installPhase = lib.concatStringsSep "\n" (lib.mapAttrsToList installPlugin plugins);
  };

in stdenv.mkDerivation {
  pname = "helm-with-plugins";
  version = kubernetes-helm.version;

  phases = [ "installPhase" ];
  buildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    ln -s ${kubernetes-helm}/bin/helm $out/bin
    wrapProgram "$out/bin/helm" --set HELM_PLUGINS "${helm-plugins}"
  '';
}
