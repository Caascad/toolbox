{ pkgs, lib }:

let

 python39Pkgs = pkgs.python39.pkgs;

 quantiphy = python39Pkgs.buildPythonPackage {
    pname = "quantiphy";
    version = "2.15.0";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/2b/74/9d8f92e4a2f0fa4b16e02dcb865f1eb0098fc5efa2d20bd06753a50048fe/quantiphy-2.15.0-py3-none-any.whl";
      sha256 = "1gd02bw30gcnyfallqp3g0jrn1bhnligv692aimr4irl4wficmqi";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };

in 

python39Pkgs.buildPythonApplication {
  name = "rebalancer";

  src = lib.cleanSource ./src;

  propagatedBuildInputs = with pkgs.python39Packages; [ kubernetes quantiphy urllib3 ];
}
