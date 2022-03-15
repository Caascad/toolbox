{ sources ? import ./nix/sources.nix
, nixpkgs ? sources.nixpkgs
, nixpkgs-old ? sources.nixpkgs-old
}:

let

  pkgs = import nixpkgs {
    overlays = [(self: super: {

      terraform-providers = super.terraform-providers // {

        kubernetes-alpha = {};

        aws = pkgs.callPackage ./pkgs/terraform-provider-aws.nix
          { source = sources.terraform-provider-aws; };

        controltower = pkgs.callPackage ./pkgs/terraform-provider-controltower.nix
          { source = sources.terraform-provider-controltower; };

        k8sraw = builtins.trace "k8sraw provider is deprecated, use the kubectl provider" pkgs.callPackage ./pkgs/terraform-provider-k8sraw.nix
          { source = sources.terraform-provider-kubernetes-yaml; };

        rancher2 = pkgs.callPackage ./pkgs/terraform-provider-rancher2.nix
          { source = sources.terraform-provider-rancher2; };

        kubectl = pkgs.callPackage ./pkgs/terraform-provider-kubectl.nix
          { source = sources.terraform-provider-kubectl; };

        concourse = pkgs.callPackage ./pkgs/terraform-provider-concourse.nix
          { source = sources.terraform-provider-concourse; };

        gitlab = pkgs.callPackage ./pkgs/terraform-provider-gitlab.nix
          { source = sources.terraform-provider-gitlab; };

        flexibleengine = super.terraform-providers.flexibleengine.overrideAttrs (old:
          with sources.terraform-provider-flexibleengine; {
            inherit version;
            pname = repo;
            src = pkgs.fetchzip {
              inherit url sha256;
            };
            postBuild = "mv go/bin/${repo}{,_v${version}}";
            passthru.provider-source-address = "registry.terraform.io/toolbox/flexibleengine";
          }
        );

        huaweicloud = pkgs.callPackage ./pkgs/terraform-provider-huaweicloud.nix
          { source = sources.terraform-provider-huaweicloud; };

        azuread = pkgs.callPackage ./pkgs/terraform-provider-azuread.nix
          { source = sources.terraform-provider-azuread; };

        azurerm = pkgs.callPackage ./pkgs/terraform-provider-azurerm.nix
          { source = sources.terraform-provider-azurerm; };

        helm = super.terraform-providers.helm.overrideAttrs (old:
          with sources.terraform-provider-helm; {
            inherit version;
            pname = repo;
            goPackagePath = "github.com/hashicorp/${repo}";
            src = pkgs.fetchzip {
              inherit url sha256;
            };
            postBuild = "mv ../go/bin/${repo}{,_v${version}}";
            passthru.provider-source-address = "registry.terraform.io/toolbox/helm";
          }
        );

        kubernetes = super.terraform-providers.kubernetes.overrideAttrs (old:
          with sources.terraform-provider-kubernetes; {
            inherit version;
            pname = repo;
            goPackagePath = "github.com/hashicorp/${repo}";
            src = pkgs.fetchzip {
              inherit url sha256;
            };
            postBuild = "mv ../go/bin/${repo}{,_v${version}}";
            passthru.provider-source-address = "registry.terraform.io/toolbox/kubernetes";
          }
        );

        vault = pkgs.callPackage ./pkgs/terraform-provider-vault.nix
          { source = sources.terraform-provider-vault; };

        keycloak = super.terraform-providers.keycloak.overrideAttrs (old:
           {
            passthru.provider-source-address = "registry.terraform.io/toolbox/keycloak";
          }
        );

        cloudinit = super.terraform-providers.cloudinit.overrideAttrs (old:
          with sources.terraform-provider-cloudinit; {
            inherit version;
            pname = repo;
            src = pkgs.fetchzip {
              inherit url sha256;
            };
            postBuild = "mv ../go/bin/${repo}{,_v${version}}";
            passthru.provider-source-address = "registry.terraform.io/toolbox/cloudinit";
          }
        );

      };

    })];
  };


in

with pkgs.lib;

rec {

  # Expose all nixpkgs packages in `pkgs` attribute
  inherit pkgs;

  inherit (pkgs) kubectl stern vault docker-compose cfssl kompose
                 yq jq gopass kubectx  direnv go gnupg curl
                 kustomize pre-commit shellcheck terraform-docs tflint
                 envsubst awscli restic azure-cli
                 saml2aws
                 k9s
                 terraform_0_13 terraform_0_14 terraform_0_15 terraform_1;

  terraform_1_0_0 = builtins.trace "terraform_1_0_0 is deprecated use terraform_1_0" terraform_1_0;
  terraform_1_0 = builtins.trace "terraform_1_0 is deprecated use terraform_1" terraform_1;

  ansible = pkgs.ansible_2_9;

  amtool = pkgs.callPackage ./pkgs/amtool.nix {};

  helm = pkgs.kubernetes-helm;

  # Expose providers that don't come from nixpkgs (so that we can push them in the cache)
  terraform-providers = filterAttrs (_: drv:
    if drv ? "passthru" && drv.passthru ? "provider-source-address" then
      let components = splitString "/" drv.passthru.provider-source-address;
      in (builtins.elemAt components 1) == "toolbox"
    else false) pkgs.terraform-providers;

  cue = pkgs.callPackage ./pkgs/cue.nix { source = sources.cue; };

  fly = pkgs.callPackage ./pkgs/fly.nix { inherit sources; };

  kubectl-plugins = pkgs.callPackages ./pkgs/kubectl-plugins { inherit sources; };

  kubectl-with-plugins = pkgs.callPackage ./pkgs/kubectl-with-plugins.nix
    { plugins = kubectl-plugins; };

  helm-plugins = pkgs.callPackages ./pkgs/helm-plugins { inherit sources; };

  helm-with-plugins = pkgs.callPackage ./pkgs/helm-with-plugins.nix
    { plugins = helm-plugins; };

  ansible-plugins = pkgs.callPackages ./pkgs/ansible-plugins {};

  ansible-with-plugins = pkgs.callPackage ./pkgs/ansible-with-plugins.nix
    { plugins = ansible-plugins; inherit ansible; };

  kswitch = pkgs.callPackage ./pkgs/kswitch {};

  toolbox = pkgs.callPackage ./pkgs/toolbox {};

  logcli = pkgs.callPackage ./pkgs/loki.nix
    { source = sources.loki; };

  vault-token-helper = pkgs.callPackage ./pkgs/vault-token-helper.nix
    { source = sources.vault-token-helper; };

  velero = pkgs.callPackage ./pkgs/velero.nix
    { source = sources.velero; };

  promtool = pkgs.callPackage ./pkgs/promtool.nix {};

  sd = import sources.sd.outPath { inherit pkgs; };

  rswitch = import sources.rswitch.outPath { inherit pkgs; };

} // optionalAttrs (! pkgs.stdenv.isDarwin) rec {

  openstackclient = pkgs.callPackage ./pkgs/openstack-cli {};

  os = pkgs.callPackage ./pkgs/os { inherit openstackclient; };

}
