{ sources ? import ./nix/sources.nix
, nixpkgs ? sources.nixpkgs
}:

let

  pkgs = import nixpkgs {};

  terraform-providers = {

    keycloak = pkgs.callPackage ./pkgs/terraform-provider-keycloak.nix
      { source = sources.terraform-provider-keycloak; };

    k8sraw = pkgs.callPackage ./pkgs/terraform-provider-k8sraw.nix
      { source = sources.terraform-provider-kubernetes-yaml; };

    concourse = pkgs.callPackage ./pkgs/terraform-provider-concourse
      { source = sources.terraform-provider-concourse; };

    flexibleengine = pkgs.terraform-providers.flexibleengine.overrideAttrs (old:
      with sources.terraform-provider-flexibleengine; {
        inherit version;
        name = "${repo}-${version}";
        src = pkgs.fetchzip {
          inherit url sha256;
        };
        postBuild = "mv go/bin/${repo}{,_v${version}}";
      }
    );

    huaweicloud = pkgs.terraform-providers.huaweicloud.overrideAttrs (old: {
      patches = [ ./pkgs/terraform-provider-huaweicloud-urls.patch ];
    });

  };

in

with pkgs.lib;

rec {

  inherit (pkgs) kubectl stern vault docker-compose cfssl kompose
                 yq jq gopass kubectx awscli direnv cue go gnupg curl kustomize;

  ansible = pkgs.ansible_2_9;

  helm = pkgs.kubernetes-helm;

  inherit terraform-providers;

  terraform-minimal = pkgs.terraform_0_12;

  terraform = pkgs.terraform_0_12.withPlugins (p: [
    terraform-providers.concourse
    terraform-providers.flexibleengine
    terraform-providers.huaweicloud
    terraform-providers.k8sraw
    terraform-providers.keycloak
    p.aws
    p.external
    p.kubernetes
    p.local
    p.null
    p.openstack
    p.rancher2
    p.random
    p.template
    p.tls
    p.vault
  ]);

  pre-commit-terraform = pkgs.callPackage ./pkgs/pre-commit-terraform.nix
    { pythonPackages = pkgs.python38Packages; inherit terraform; };

  fly = pkgs.callPackage ./pkgs/fly.nix
    { source = sources.concourse; };

  tf = import sources.tf.outPath {};

  kswitch = pkgs.callPackage ./pkgs/kswitch {};

  toolbox = pkgs.callPackage ./pkgs/toolbox {};

  internal-ca = pkgs.callPackage ./pkgs/internal-ca.nix
    { source = sources.internal-ca; };

  vault-token-helper = pkgs.callPackage ./pkgs/vault-token-helper.nix
    { source = sources.vault-token-helper; };

} // optionalAttrs (! pkgs.stdenv.isDarwin) {

  # doesn't build on MacOS
  openstackclient = pkgs.callPackage ./pkgs/openstackclient {};

  os = import sources.os.outPath { toolbox = ./.; };

}
