{ sources ? import ./nix/sources.nix
, nixpkgs ? sources.nixpkgs
, pkgs ? import nixpkgs {}
}:

let

  terraform-provider-keycloak = pkgs.callPackage ./pkgs/terraform-provider-keycloak.nix
    { source = sources.terraform-provider-keycloak; };

in {

  inherit (pkgs) ansible;

  terraform = pkgs.terraform_0_12.withPlugins (p: [ p.local p.openstack terraform-provider-keycloak ]);

}
