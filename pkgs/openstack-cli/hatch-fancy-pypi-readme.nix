# TODO: remove when https://github.com/NixOS/nixpkgs/pull/187999 is merged
{ pkgs
, lib
, python
}:

let
  pythonPkgs = python.pkgs;
in
  pythonPkgs.buildPythonPackage rec {
    pname = "hatch-fancy-pypi-readme";
    version = "22.3.0";
    format = "pyproject";
  
    disabled = pythonPkgs.pythonOlder "3.7";
  
    src = pythonPkgs.fetchPypi {
      pname = "hatch_fancy_pypi_readme";
      inherit version;
      hash = "sha256-fUZR+PB4JZMckoc8tRE3IUqTi623p1m4XB2Vv3T4bvo=";
    };
  
    nativeBuildInputs = [
      pythonPkgs.hatchling
    ];
  
    propagatedBuildInputs = [
      pythonPkgs.hatchling
    ];
  
    checkInputs = [
      pythonPkgs.build
      pythonPkgs.pytestCheckHook
    ];
  
    disabledTests = [
      "test_build"
      "test_invalid_config"
    ];
  
    pythonImportsCheck = [
      "hatch_fancy_pypi_readme"
    ];
  
    meta = with lib; {
      description = "Fancy PyPI READMEs with Hatch";
      homepage = "https://github.com/hynek/hatch-fancy-pypi-readme";
      license = licenses.mit;
      maintainers = ["xmaillard"];
    };
  }
