{ pkgs
, lib
}:

let
  openstackEnv = pkgs.poetry2nix.mkPoetryEnv {
    projectDir = ./.;
    python = pkgs.python310;
    overrides = pkgs.poetry2nix.overrides.withDefaults (self: super: rec {

      # TODO: remove when poetry2nix's override contains this
      jsonschema = super.jsonschema.overridePythonAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          hatch-fancy-pypi-readme
        ];
      });

      # TODO: remove when https://github.com/NixOS/nixpkgs/pull/187999 is merged
      hatch-fancy-pypi-readme = pkgs.callPackage ./hatch-fancy-pypi-readme.nix {
        python = super.python;
      };

      munch = super.munch.overridePythonAttrs (old: {
        propagatedBuildInputs = old.propagatedBuildInputs ++ [ self.pbr self.six ];
      });

      warlock = super.warlock.overridePythonAttrs (old: {
        propagatedBuildInputs = old.propagatedBuildInputs ++ [ self.poetry ];
      });

      python-swiftclient = super.python-swiftclient.overridePythonAttrs (old: {
        propagatedBuildInputs = old.propagatedBuildInputs ++ [ self.pbr ];
      });

      python-octaviaclient = super.python-octaviaclient.overridePythonAttrs (old: { 
        preConfigure = '' 
          sed -i 's/load-balancer/network/' ./octaviaclient/osc/plugin.py 
        ''; 
      });

      requestsexceptions = super.requestsexceptions.overridePythonAttrs (old: {
        propagatedBuildInputs = old.propagatedBuildInputs ++ [ self.pbr ];
      });

      futurist = super.futurist.overridePythonAttrs (old: {
        propagatedBuildInputs = old.propagatedBuildInputs ++ [ self.pbr ];
      });

      pbr = super.pbr.overridePythonAttrs(old: {
        # This is because pbr relies on pkgs_resource (provided by setuptools)
        prePatch = ''substituteInPlace pbr/version.py --replace 'self.semantic_version().brief_string()' '"${self.python-openstackclient.version}"' '';
      });

    });
  };

  openstackCLI = pkgs.writers.writeBashBin "openstack"
    "${openstackEnv}/bin/python -c 'import openstackclient.shell; openstackclient.shell.main()' $@";

in openstackCLI.overrideAttrs (old: rec {
  pname = "openstackclient";
  version = "6.0.0";
  name = "${pname}-${version}";

  meta = with lib; {
    description = "CLI client for OpenStack";
    homepage = "https://pypi.org/project/python-openstackclient/";
    license = licenses.asl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
})
