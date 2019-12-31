{ sources ? import ./nix/sources.nix
, nixpkgs ? sources.nixpkgs
, nixpkgs-unstable ? sources.nixpkgs-unstable
}:

let

  pkgs = import nixpkgs {};
  pkgs-unstable = import nixpkgs-unstable {};

  terraform-provider-keycloak = pkgs.callPackage ./pkgs/terraform-provider-keycloak.nix
    { source = sources.terraform-provider-keycloak; };

in {

  inherit (pkgs) ansible kubectl stern vault docker-compose fly cfssl yq jq;

  helm = pkgs-unstable.kubernetes-helm;

  terraform = pkgs.terraform_0_12.withPlugins (p: [
    p.aws p.openstack p.vault terraform-provider-keycloak
    p.local p.null p.random p.tls p.template
  ]);

  safe = pkgs.callPackage ./pkgs/safe.nix
    { source = sources.safe; };

}
