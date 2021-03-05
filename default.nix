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

        vault = super.terraform-providers.vault.overrideAttrs (old:
          with sources.terraform-provider-vault; {
            inherit version;
            pname = repo;
            src = pkgs.fetchzip {
              inherit url sha256;
            };
            postBuild = "mv go/bin/${repo}{,_v${version}}";
            passthru.provider-source-address = "registry.terraform.io/toolbox/vault";
          }
        );

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
                 saml2aws envsubst awscli restic azure-cli;

  ansible = pkgs.ansible_2_9;

  amtool = pkgs.callPackage ./pkgs/amtool.nix {};

  helm = pkgs.kubernetes-helm;

  terraform-minimal = pkgs.terraform_0_12;

  terraform = pkgs.terraform_0_12.withPlugins (p: with p; [
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
    template
    tls
    p.vault
  ]);

  terraform_0_13 = pkgs.terraform_0_13;

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

} // optionalAttrs (! pkgs.stdenv.isDarwin) {

  # doesn't build on MacOS
  # FIXME: rebuild with latest nixpkgs
  openstackclient = let
    pkgs = import nixpkgs-old {};
  in
    pkgs.callPackage ./pkgs/openstackclient {};

  os = import sources.os.outPath { toolbox = ./.; };
  sd = import sources.sd.outPath { toolbox = ./.; };

}
