{ pkgs, lib, python }:

let

 pythonPkgs = python.pkgs;

 # Tests are failing on darwin
 kubernetes = pythonPkgs.kubernetes.overridePythonAttrs (old: {
   doCheck = false;
 });

 quantiphy = pythonPkgs.buildPythonPackage rec {
    pname = "quantiphy";
    version = "2.17.0";

    src = pythonPkgs.fetchPypi {
      inherit pname version;
      sha256 = "0hpz2w43l5fy4qknrlzh6b6049h9yrqsgf4wh163gdbajjpfyq4n";
    };
  };

in

pythonPkgs.buildPythonApplication {
  pname = "kube-rebalancer";
  version = "0.0.1";

  src = lib.cleanSourceWith {
    filter = name: type: let baseName = baseNameOf (toString name); in baseName != "__pycache__";
    src = lib.cleanSource ./src;
  };

  propagatedBuildInputs = [ kubernetes quantiphy pythonPkgs.urllib3 ];
}
