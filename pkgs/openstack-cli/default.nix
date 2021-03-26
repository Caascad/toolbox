{ pkgs
, lib
}:

let

  openstackEnv = pkgs.poetry2nix.mkPoetryEnv {
    projectDir = ./.;
    python = pkgs.python38;
    overrides = pkgs.poetry2nix.overrides.withDefaults (self: super: {

      munch = super.munch.overridePythonAttrs (old: {
          propagatedBuildInputs = old.propagatedBuildInputs ++ [ self.pbr self.six ];
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
  version = "5.5.0";
  name = "${pname}-${version}";

  meta = with lib; {
    description = "CLI client for OpenStack";
    homepage = "https://pypi.org/project/python-openstackclient/";
    license = licenses.asl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
})
