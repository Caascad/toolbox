{ sources ? import ./nix/sources.nix
, nixpkgs ? sources.nixpkgs
, nixpkgs-unstable ? sources.nixpkgs-unstable
}:

let

  pkgs = import nixpkgs {};
  pkgs-unstable = import nixpkgs-unstable {};

  terraform-provider-keycloak = pkgs.callPackage ./pkgs/terraform-provider-keycloak.nix
    { source = sources.terraform-provider-keycloak; };

  # Support for helm v3 is not yet merged
  # https://github.com/terraform-providers/terraform-provider-helm/pull/378
  terraform-provider-helm = pkgs.terraform-providers.helm.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "terraform-providers";
      repo = "terraform-provider-helm";
      rev = "a5cce939b484e1558a72ea2ecc915a609777f523";
      sha256 = "0l4fr5m8svfby850wsnywmlrb8dw46nc724a35h1w6sfcdxxxpi9";
    };
  });

in {

  inherit (pkgs) ansible kubectl stern vault docker-compose fly cfssl yq jq;

  helm = pkgs-unstable.kubernetes-helm;

  terraform = pkgs.terraform_0_12.withPlugins (p: [
    terraform-provider-helm terraform-provider-keycloak
    p.aws p.openstack p.vault p.kubernetes
    p.local p.null p.random p.tls p.template
  ]);

  safe = pkgs.callPackage ./pkgs/safe.nix
    { source = sources.safe; };

}
