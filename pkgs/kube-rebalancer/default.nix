{ pkgs, lib, python }:

let

 pythonPkgs = python.pkgs;

 # Tests are failing on darwin
 kubernetes = pythonPkgs.kubernetes.overridePythonAttrs (old: {
   doCheck = false;
 });

in

pythonPkgs.buildPythonApplication {
  pname = "kube-rebalancer";
  version = "0.0.1";

  src = lib.cleanSourceWith {
    filter = name: type: let baseName = baseNameOf (toString name); in baseName != "__pycache__";
    src = lib.cleanSource ./src;
  };

  propagatedBuildInputs = [ kubernetes pythonPkgs.quantiphy pythonPkgs.urllib3 ];
}
