{ pkgs, lib, python }:

let

 pythonPkgs = python.pkgs;

 # Tests are failing on darwin
 kubernetes = pythonPkgs.kubernetes.overridePythonAttrs (old: {
   doCheck = false;
 });

 quantiphy = pythonPkgs.buildPythonPackage rec {
    pname = "quantiphy";
    version = "2.18.0";

    src = pythonPkgs.fetchPypi {
      inherit pname version;
      sha256 = "sha256-7KFKv6g8MXHOpyEqGhH9bgBNAp5VALNCsmC0jHL1DWY=";
    };
  };

in

pythonPkgs.buildPythonApplication {
  pname = "kube-rebalancer";
  version = "0.0.1";
  doCheck = false;
  src = lib.cleanSourceWith {
    filter = name: type: let baseName = baseNameOf (toString name); in baseName != "__pycache__";
    src = lib.cleanSource ./src;
  };

  propagatedBuildInputs = [ kubernetes quantiphy pythonPkgs.urllib3 ];
}
