{ pkgs, python }:

self: super: rec {

  requestsexceptions = python.overrideDerivation super.requestsexceptions (old: {
    propagatedBuildInputs = old.propagatedBuildInputs ++ [ self.pbr ];
  });

  munch = python.overrideDerivation super.munch (old: {
    propagatedBuildInputs = old.propagatedBuildInputs ++ [ self.pbr ];
  });

  python-octaviaclient = python.overrideDerivation super.python-octaviaclient (old: {
    preConfigure = ''
      sed -i 's/load-balancer/network/' ./octaviaclient/osc/plugin.py
    '';
  });

  otcextensions = python.overrideDerivation super.otcextensions (old: {
    preConfigure = ''
      sed -i "s/eu-de.otc.t-systems.com/eu-west-0.prod-cloud-ocb.orange-business.com/g" ./otcextensions/sdk/cce/cce_service.py
      sed -i "s/otc.t-systems.com/prod-cloud-ocb.orange-business.com/g" ./otcextensions/sdk/obs/v1/_proxy.py
      sed -i "s/s\.obs\./s.oss./g" ./otcextensions/sdk/obs/v1/_proxy.py
    '';
  });

  openstackclient = with super;
    let
      drv = python.withPackages { inherit python-openstackclient python-octaviaclient otcextensions; };
      name = "openstackclient-${(builtins.parseDrvName(super.python-openstackclient.name)).version}";
    in drv.interpreter.overrideDerivation (old: {
      inherit name;
      # keep only bin/openstack
      buildCommand = old.buildCommand + ''rm $out/bin/.python* $out/bin/python*'';
    });
}
