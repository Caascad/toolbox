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

    rancher2 = pkgs.callPackage ./pkgs/terraform-provider-rancher2.nix
      { source = sources.terraform-provider-rancher2; };

    vault = pkgs.terraform-providers.vault.overrideAttrs (old:
      with sources.terraform-provider-vault; {
        inherit version;
        name = "${repo}-${version}";
        src = outPath;
        postBuild = "mv go/bin/${repo}{,_v${version}}";
      }
    );

    flexibleengine = pkgs.terraform-providers.flexibleengine.overrideAttrs (old:
      with sources.terraform-provider-flexibleengine; {
        inherit version;
        name = "${repo}-${version}";
        src = outPath;
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

  inherit (pkgs) ansible kubectl stern vault docker-compose cfssl
                 yq jq gopass kubectx awscli direnv cue go gnupg curl;

  helm = pkgs.kubernetes-helm;

  inherit terraform-providers;

  terraform = pkgs.terraform_0_12.withPlugins (p: [
    terraform-providers.concourse
    terraform-providers.flexibleengine
    terraform-providers.huaweicloud
    terraform-providers.k8sraw
    terraform-providers.keycloak
    terraform-providers.rancher2
    terraform-providers.vault
    p.aws
    p.external
    p.kubernetes
    p.local
    p.null
    p.openstack
    p.random
    p.template
    p.tls
  ]);

  safe = pkgs.callPackage ./pkgs/safe.nix
    { source = sources.safe; };

  fly = pkgs.callPackage ./pkgs/fly.nix
    { source = sources.concourse; };

  tf = pkgs.callPackage ./pkgs/tf.nix
    { source = sources.tf; inherit terraform; };

  kswitch = pkgs.callPackage ./pkgs/kswitch {};

  toolbox = pkgs.callPackage ./pkgs/toolbox {};

  internal-ca = pkgs.callPackage ./pkgs/internal-ca.nix
    { source = sources.internal-ca; };

  vault-token-helper = pkgs.callPackage ./pkgs/vault-token-helper.nix
    { source = sources.vault-token-helper; };

} // optionalAttrs (! pkgs.stdenv.isDarwin) {
  # doesn't build on MacOS

  openstackclient = pkgs.callPackage ./pkgs/openstackclient {};

}
