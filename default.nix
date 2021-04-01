{ sources ? import ./nix/sources.nix
, nixpkgs ? sources.nixpkgs
, nixpkgs-old ? sources.nixpkgs-old
}:

let

  pkgs = import nixpkgs {
    overlays = [(self: super: {

      terraform-providers = super.terraform-providers // {

        aws = pkgs.callPackage ./pkgs/terraform-provider-aws.nix
          { source = sources.terraform-provider-aws; };

        k8sraw = pkgs.callPackage ./pkgs/terraform-provider-k8sraw.nix
          { source = sources.terraform-provider-kubernetes-yaml; };

        rancher2 = pkgs.callPackage ./pkgs/terraform-provider-rancher2.nix
          { source = sources.terraform-provider-rancher2; };

        kubectl = pkgs.callPackage ./pkgs/terraform-provider-kubectl.nix
          { source = sources.terraform-provider-kubectl; };

        concourse = pkgs.callPackage ./pkgs/terraform-provider-concourse.nix
          { source = sources.terraform-provider-concourse; };

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

        huaweicloud = super.terraform-providers.huaweicloud.overrideAttrs (old: {
          patches = [ ./pkgs/terraform-provider-huaweicloud-urls.patch ];
          passthru.provider-source-address = "registry.terraform.io/toolbox/huaweicloud";
        });

        azuread = pkgs.callPackage ./pkgs/terraform-provider-azuread.nix
          { source = sources.terraform-provider-azuread; };

        azurerm = pkgs.callPackage ./pkgs/terraform-provider-azurerm.nix
          { source = sources.terraform-provider-azurerm; };

        vault = super.terraform-providers.vault.overrideAttrs (old:
          with sources.terraform-provider-vault; {
            inherit version;
            pname = repo;
            goPackagePath = "github.com/hashicorp/${repo}";
            src = pkgs.fetchzip {
              inherit url sha256;
            };
            postBuild = "mv go/bin/${repo}{,_v${version}}";
            passthru.provider-source-address = "registry.terraform.io/toolbox/vault";
          }
        );
        
        restapi = pkgs.callPackage ./pkgs/terraform-provider-restapi.nix
          { source = sources.terraform-provider-restapi; };


        keycloak = pkgs.callPackage ./pkgs/terraform-provider-keycloak.nix
          { source = sources.terraform-provider-keycloak; };

        cloudinit = super.terraform-providers.cloudinit.overrideAttrs (old:
          with sources.terraform-provider-cloudinit; {
            inherit version;
            pname = repo;
            src = pkgs.fetchzip {
              inherit url sha256;
            };
            postBuild = "mv go/bin/${repo}{,_v${version}}";
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
                 yq jq gopass kubectx  direnv cue go gnupg curl
                 kustomize pre-commit shellcheck terraform-docs tflint
                 saml2aws envsubst awscli restic azure-cli
                 terraform_0_12 terraform_0_13 terraform_0_14;

  ansible = pkgs.ansible_2_9;

  amtool = pkgs.callPackage ./pkgs/amtool.nix {};

  helm = pkgs.kubernetes-helm;

  # Expose providers that don't come from nixpkgs (so that we can push them in the cache)
  terraform-providers = filterAttrs (_: drv:
    if drv ? "passthru" && drv.passthru ? "provider-source-address" then
      let components = splitString "/" drv.passthru.provider-source-address;
      in (builtins.elemAt components 1) == "toolbox"
    else false) pkgs.terraform-providers;

  terraform = trace "Warning: terraform attribute is deprecated, use terraform_(0_12|0_13|0_14) or toolbox make-terraform(12|13|14)-shell" pkgs.terraform_0_12.withPlugins (p: with p; [
    aws
    concourse
    external
    flexibleengine
    http
    huaweicloud
    k8sraw
    keycloak
    kubernetes
    local
    p.null
    openstack
    rancher2
    random
    restapi
    template
    tls
    p.vault
  ]);

  terraform-minimal = trace "Warning: terraform-minimal is deprecated use terraform_0_12" pkgs.terraform_0_12;

  cue_0_3 = pkgs.callPackage ./pkgs/cue.nix { source = sources.cue; };

  fly = pkgs.callPackage ./pkgs/fly.nix { inherit sources; };

  kubectl-plugins = pkgs.callPackages ./pkgs/kubectl-plugins { inherit sources; };

  kubectl-with-plugins = pkgs.callPackage ./pkgs/kubectl-with-plugins.nix
    { plugins = kubectl-plugins; };

  helm-plugins = pkgs.callPackages ./pkgs/helm-plugins { inherit sources; };

  helm-with-plugins = pkgs.callPackage ./pkgs/helm-with-plugins.nix
    { plugins = helm-plugins; };

  kswitch = pkgs.callPackage ./pkgs/kswitch {};

  toolbox = pkgs.callPackage ./pkgs/toolbox {};

  logcli = pkgs.callPackage ./pkgs/loki.nix
    { source = sources.loki; };

  vault-token-helper = pkgs.callPackage ./pkgs/vault-token-helper.nix
    { source = sources.vault-token-helper; };

  velero = pkgs.callPackage ./pkgs/velero.nix
    { source = sources.velero; };

} // optionalAttrs (! pkgs.stdenv.isDarwin) rec {

  openstackclient = pkgs.callPackage ./pkgs/openstack-cli {};

  os = pkgs.callPackage ./pkgs/os { inherit openstackclient; };

  sd = import sources.sd.outPath { toolbox = ./.; };

}
