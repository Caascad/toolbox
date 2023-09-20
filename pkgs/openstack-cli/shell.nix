let
  nixpkgs-poetry = import (builtins.fetchTarball {
    url = "https://github.com/NixOs/nixpkgs/archive/21de2b973f9fee595a7a1ac4693efff791245c34.tar.gz";
    sha256 = "1kicpg62jsyh4blyykvbkq1vg4rv56k22qpp8kr9mj3fjabkrr27";
  }) {};
  pkgs = nixpkgs-poetry.pkgs;

in with pkgs; pkgs.runCommand "deps" {
  buildInputs = [
    python3Packages.virtualenv gcc poetry
  ];
  shellHook = ''
    #virtualenv /tmp/venv
    #source /tmp/venv/bin/activate
    #pip install openstackclient python-octaviaclient otcextensions
    #poetry init -n
    #pip freeze | sed 's/ @.*$//' | sed '/poetry/d' | sed '/virtualenv/d' | sed '/keyring/d' | xargs poetry add
    #deactivate
    poetry add cryptography@40.0.2 # may be updated with nixpkgs. Poetry tries to update this module but new versions modules sha are not in nixpkgs
    #rm -rf /tmp/venv
    '';
} ""
