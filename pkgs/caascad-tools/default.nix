{ pkgs
, openstackclient
, kswitch
, vault
, curl
, sd
, jq
, sedutil
}:
with pkgs;
stdenv.mkDerivation {
  pname = "caascad-tools";
  version = "1.0.0";

  buildInputs = [ makeWrapper ];
  passAsFile = [ "buildCommand" ];
  buildCommand = ''
    mkdir -p $out/bin
    
    cp ${./caascad-openstack.sh} $out/bin/caascad-openstack
    chmod +x $out/bin/caascad-openstack
    wrapProgram $out/bin/caascad-openstack --prefix PATH ":" ${lib.makeBinPath [ openstackclient vault curl jq sedutil ]}
    
    cp ${./caascad-node-delete.sh} $out/bin/caascad-node-delete
    chmod +x $out/bin/caascad-node-delete
    wrapProgram $out/bin/caascad-node-delete --prefix PATH ":" ${lib.makeBinPath [ openstackclient kswitch jq sd ]}
    
    cp ${./caascad-trackbone-shell.sh} $out/bin/caascad-trackbone-shell
    chmod +x $out/bin/caascad-trackbone-shell
  '';

  meta = with lib; {
    description = "Caascad helper scripts";
    homepage = "https://github.com/Caascad/toolbox";
    license = licenses.mit;
    maintainers = with maintainers; [ "Benjile" ];
  };
}
