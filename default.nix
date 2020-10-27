{ sources ? import ./nix/sources.nix
, nixpkgs ? sources.nixpkgs
}:

let

  pkgs = import nixpkgs {
    overlays = [(self: super: {

      terraform-providers = super.terraform-providers // {

        aws = super.terraform-providers.aws.overrideAttrs (old:
          with sources.terraform-provider-aws; {
            inherit version;
            name = "${repo}-${version}";
            src = pkgs.fetchzip {
              inherit url sha256;
            };
            postBuild = "mv go/bin/${repo}{,_v${version}}";
          }
        );

        k8sraw = pkgs.callPackage ./pkgs/terraform-provider-k8sraw.nix
          { source = sources.terraform-provider-kubernetes-yaml; };

        concourse = pkgs.callPackage ./pkgs/terraform-provider-concourse
          { source = sources.terraform-provider-concourse; };

        flexibleengine = super.terraform-providers.flexibleengine.overrideAttrs (old:
          with sources.terraform-provider-flexibleengine; {
            inherit version;
            name = "${repo}-${version}";
            src = pkgs.fetchzip {
              inherit url sha256;
            };
            postBuild = "mv go/bin/${repo}{,_v${version}}";
          }
        );

        huaweicloud = super.terraform-providers.huaweicloud.overrideAttrs (old: {
          patches = [ ./pkgs/terraform-provider-huaweicloud-urls.patch ];
        });

      };

    })];
  };


in

with pkgs.lib;

rec {

  # Expose all nixpkgs packages in `pkgs` attribute
  inherit pkgs;

  inherit (pkgs) kubectl stern vault docker-compose cfssl kompose
                 yq jq gopass kubectx awscli direnv cue go gnupg curl
                 kustomize pre-commit shellcheck terraform-docs tflint;

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
    null
    openstack
    rancher2
    random
    template
    tls
    p.vault
  ]);

  fly = pkgs.callPackage ./pkgs/fly.nix { inherit sources; };

  kubectl-plugins = pkgs.callPackages ./pkgs/kubectl-plugins { inherit sources; };

  kubectl-with-plugins = pkgs.callPackage ./pkgs/kubectl-with-plugins.nix
    { plugins = kubectl-plugins; };

  helm-plugins = pkgs.callPackages ./pkgs/helm-plugins { inherit sources; };

  helm-with-plugins = pkgs.callPackage ./pkgs/helm-with-plugins.nix
    { plugins = helm-plugins; };

  tf = import sources.tf.outPath {};

  kswitch = pkgs.callPackage ./pkgs/kswitch {};

  krew = pkgs.callPackage ./pkgs/krew {};

  toolbox = pkgs.callPackage ./pkgs/toolbox {};

  internal-ca = pkgs.callPackage ./pkgs/internal-ca.nix
    { source = sources.internal-ca; };

  logcli = pkgs.callPackage ./pkgs/loki.nix
    { source = sources.loki; };

  vault-token-helper = pkgs.callPackage ./pkgs/vault-token-helper.nix
    { source = sources.vault-token-helper; };

  velero = pkgs.callPackage ./pkgs/velero.nix
    { source = sources.velero; };

} // optionalAttrs (! pkgs.stdenv.isDarwin) {

  # doesn't build on MacOS
  openstackclient = pkgs.callPackage ./pkgs/openstackclient {};

  os = import sources.os.outPath { toolbox = ./.; };

}
