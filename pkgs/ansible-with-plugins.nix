{ pkgs
, stdenv
, lib
, makeWrapper
, plugins
, ansible
}:

let

  callbackPluginsPaths = lib.concatStringsSep ":" (lib.mapAttrsToList (_: drv: "${drv}/callback") plugins);
  callbackPlugins = lib.concatStringsSep ":" (builtins.attrNames plugins);

in stdenv.mkDerivation {
  pname = "ansible";
  version = ansible.version;

  phases = [ "installPhase" ];
  buildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    ln -s ${ansible}/bin/ansible* $out/bin
    wrapProgram "$out/bin/ansible-playbook" --set ANSIBLE_CALLBACK_PLUGINS "${callbackPluginsPaths}" --set ANSIBLE_CALLBACKS_ENABLED "${callbackPlugins}"
  '';
}
