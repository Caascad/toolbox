# FIXME-1
  # nixpkgs golang builders migrate to SRI hash (sha256-*)
  # should be inherited from source but niv does not provide this attribute
{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs {}
, poetry2nixStandalone ? import sources.poetry2nix {}
}:

let

  providersSource = pkgs.lib.importJSON ./autoupdate/providers.json;
  automated-providers = pkgs.lib.mapAttrs (_: attrs: pkgs.terraform-providers.mkProvider attrs) providersSource;
  special-providers = {
    harbor = automated-providers.harbor.override {mkProviderGoModule = pkgs.buildGo122Module;};
  };

in
with pkgs;
with pkgs.lib;

rec {

  # Expose all nixpkgs packages in `pkgs` attribute
  inherit pkgs;

  inherit (pkgs) nix kapp kubectl stern vault docker-compose cfssl kompose ansible
                 yq jq gopass kubectx  direnv go gnupg curl
                 kustomize shellcheck
                 envsubst awscli restic azure-cli
                 saml2aws
                 k9s
                 terraform_1 terraform-docs tflint
                 cue
                 rancher
                 ;

  terraform_1_0_0 = builtins.trace "terraform_1_0_0 is deprecated use terraform_1" terraform_1;
  terraform_1_0 = builtins.trace "terraform_1_0 is deprecated use terraform_1" terraform_1;

  open-policy-agent = pkgs.open-policy-agent.overrideAttrs  {
    # Tests related to wasm are failing on MacOS
    # but wasm is not enabled in the build
    doCheck = false;
  };

  pre-commit = pkgs.pre-commit.overrideAttrs (old: rec {
    pname = "pre-commit";
    version = old.version;
    name = "${pname}-${version}";
  });

  amtool = callPackage ./pkgs/amtool.nix { source = sources.alertmanager; };
  amtool-caascad = callPackage ./pkgs/amtool-caascad { inherit amtool; };
  helm = kubernetes-helm;
  terraform-providers = let in { 
    inherit (pkgs.terraform-providers) azuread
                                       azurerm 
                                       aws
                                       cloudinit
                                       flexibleengine
                                       gitlab
                                       helm
                                       huaweicloud
                                       keycloak
                                       kubectl
                                       kubernetes
                                       rancher2
                                       vault
    ;} // automated-providers // special-providers;
  
  fly = callPackage ./pkgs/fly.nix { inherit sources; };

  git = pkgs.git;

  kubectl-plugins = callPackages ./pkgs/kubectl-plugins { inherit sources; };

  kubectl-with-plugins = callPackage ./pkgs/kubectl-with-plugins.nix { plugins = kubectl-plugins; };

  helm-plugins = callPackages ./pkgs/helm-plugins { inherit sources; };

  helm-with-plugins = callPackage ./pkgs/helm-with-plugins.nix { plugins = helm-plugins; };

  ansible-plugins = callPackages ./pkgs/ansible-plugins {};

  ansible-with-plugins = callPackage ./pkgs/ansible-with-plugins.nix { plugins = ansible-plugins; inherit ansible; };

  kswitch = callPackage ./pkgs/kswitch {};

  toolbox = callPackage ./pkgs/toolbox {};

  logcli = callPackage ./pkgs/loki.nix { source = sources.loki; };

  vault-token-helper = pkgs.callPackage ./pkgs/vault-token-helper.nix { source = sources.vault-token-helper; };

  velero = pkgs.callPackage ./pkgs/velero.nix { source = sources.velero; };

  tflint-ruleset-aws = pkgs.callPackage ./pkgs/tflint-ruleset-aws.nix {tflint-ruleset-aws = pkgs.tflint-plugins.tflint-ruleset-aws;};

  print-client-zones-infos = callPackage ./pkgs/print-client-zones-infos {};

  promtool = callPackage ./pkgs/promtool.nix {};

  sd = callPackage ./pkgs/sd {};

  rswitch = import sources.rswitch {inherit pkgs; poetry2nixStandalone = poetry2nixStandalone;};

  get-rancher-creds = (import sources.conformity-tooling { inherit pkgs;}).getranchercreds;

  checkmetrics = (import sources.conformity-tooling {inherit pkgs; }).checkmetrics;

  kube-rebalancer = callPackage ./pkgs/kube-rebalancer { python = pkgs.python3; };

}

