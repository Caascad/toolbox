{ sources ? import ./nix/sources.nix
, nixpkgs ? sources.nixpkgs
}:

let

  pkgs = import nixpkgs {};

  terraform-provider-keycloak = pkgs.callPackage ./pkgs/terraform-provider-keycloak.nix
    { source = sources.terraform-provider-keycloak; };

in {

  inherit (pkgs) ansible kubectl stern vault docker-compose cfssl
                 yq jq gopass kubectx aws direnv cue go;

  helm = pkgs.kubernetes-helm;

  terraform = pkgs.terraform_0_12.withPlugins (p: [
    terraform-provider-keycloak
    p.aws p.openstack p.vault p.kubernetes
    p.local p.null p.random p.tls p.template
    p.flexibleengine
  ]);

  safe = pkgs.callPackage ./pkgs/safe.nix
    { source = sources.safe; };

  fly = pkgs.callPackage ./pkgs/fly.nix
    { source = sources.concourse; };

}
