{ pkgs, python }:

let

  pythonPackages = python.pkgs;

  mkdocs-gen-files = pythonPackages.buildPythonPackage rec {
    pname = "mkdocs-gen-files";
    version = "0.3.3";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "1fwkr0a980psah56whq4g2kmbn9s0scch24q6ij20g9bnvn85zhb";
    };

    buildInputs = [ pkgs.mkdocs ];

    doCheck = false;
  };

  pymdown-extensions = pythonPackages.buildPythonPackage rec {
    pname = "pymdown-extensions";
    version = "9.0";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "0h7gk33fb4xmbkliz8g3d7yimw8w82b499w702xflsxiyk3vxr01";
    };

    propagatedBuildInputs = with pythonPackages; [ markdown ];

    # Note: tests don't pass
    # checkInputs = with pythonPackages; [ pytest pyyaml ]; 
    doCheck = false;
  };

  mkdocs-material-extensions = pythonPackages.buildPythonPackage rec {
    pname = "mkdocs-material-extensions";
    version = "1.0.3";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "18nvznxi5gcs7xhkn5pcd2hnwiw3xgwlh9p4xl9c6hbvxzylvlmz";
    };

    doCheck = false;
  };

  mkdocs-material = pythonPackages.buildPythonPackage rec {
    pname = "mkdocs-material";
    version = "7.2.3";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "1pvfjqbcr5cm2nw3knbbi0170k5jym8phs6g378aasimwxi033v8";
    };

    buildInputs = [ pkgs.mkdocs ];

    propagatedBuildInputs = with pythonPackages; [ 
      pymdown-extensions
      pygments
      mkdocs-material-extensions
    ];
  };

  mkdocs-redirects = pythonPackages.buildPythonPackage rec {
    pname = "mkdocs-redirects";
    version = "1.0.3";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "03rlzrcb739abihdfv0znni78pp85bbmk8n04y28vs7m3qfkwhfv";
    };

    buildInputs = [ pkgs.mkdocs ];

    propagatedBuildInputs = with pythonPackages; [ six ];
  };

  mkdocs-git-revision-date-localized-plugin = pythonPackages.buildPythonPackage rec {
    pname = "mkdocs-git-revision-date-localized-plugin";
    version = "0.10.0";

    # Don't use pypi because requirements.txt hasn't been uploaded
    src = pkgs.fetchFromGitHub {
      repo = "mkdocs-git-revision-date-localized-plugin";
      owner = "timvink";
      rev = "v${version}";
      sha256 = "0c2ayn5h4wy63qf8v20zh0nycac3vzj9h914f17ihcliw6zy2yry";
    };

    buildInputs = [ pkgs.mkdocs ];

    propagatedBuildInputs = with pythonPackages; [ GitPython Babel ];
  };

  env = python.buildEnv.override {
    extraLibs = with pythonPackages; [ 
      mkdocs
      # Add mkdocs plugins
      mkdocs-gen-files
      mkdocs-material
      mkdocs-redirects
      mkdocs-git-revision-date-localized-plugin
    ];
    # ignoreCollisions = true;
  };

in pkgs.writers.writeBashBin "mkdocs" "${env}/bin/mkdocs $@"
