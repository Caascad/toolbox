{ sources ? import ./nix/sources.nix
, nixpkgs ? sources.nixpkgs
, nixpkgs-old ? sources.nixpkgs-old
}:

let

  pkgs = import nixpkgs {
    overlays = [(self: super: {

      lib = super.lib // {

        # Taken and adapted from nixpkgs/pkgs/applications/networking/cluster/terraform-providers/default.nix
        mkTFProvider = super.lib.makeOverridable
          ({ source
           , deleteVendor ? false
           , proxyVendor ? false
           }:
            let
              provider-name = with super.lib; head (reverseList (splitString "-" source.repo));
              provider-source-address =  "registry.terraform.io/toolbox/${provider-name}";
            in super.buildGoModule rec {
              pname = source.repo;
              inherit (source) version;
              vendorSha256 = if source ? "vendorSha256" then source.vendorSha256 else null;
              inherit deleteVendor proxyVendor;
              subPackages = [ "." ];
              doCheck = false;
              # https://github.com/hashicorp/terraform-provider-scaffolding/blob/a8ac8375a7082befe55b71c8cbb048493dd220c2/.goreleaser.yml
              # goreleaser (used for builds distributed via terraform registry) requires that CGO is disabled
              CGO_ENABLED = 0;
              ldflags = [ "-s" "-w" "-X main.version=${version}" "-X main.commit=${source.rev}" ];
              src = super.fetchFromGitHub {
                inherit (source) owner repo rev sha256;
              };
              # Move the provider to libexec
              postInstall = ''
                dir=$out/libexec/terraform-providers/${provider-source-address}/${version}/''${GOOS}_''${GOARCH}
                mkdir -p "$dir"
                mv $out/bin/* "$dir/terraform-provider-$(basename ${provider-source-address})_${version}"
                rmdir $out/bin
              '';
              passthru = { inherit provider-source-address; };
            });
      };

      terraform-providers = super.terraform-providers // {

        aws = self.lib.mkTFProvider { source = sources.terraform-provider-aws; };

        controltower = self.lib.mkTFProvider { source = sources.terraform-provider-controltower; };

        rancher2 = self.lib.mkTFProvider { source = sources.terraform-provider-rancher2; };

        kubectl = self.lib.mkTFProvider { source = sources.terraform-provider-kubectl; };

        concourse = self.lib.mkTFProvider { source = sources.terraform-provider-concourse; };

        gitlab = self.lib.mkTFProvider { source = sources.terraform-provider-gitlab; };

        flexibleengine = self.lib.mkTFProvider { source = sources.terraform-provider-flexibleengine; };

        huaweicloud = self.lib.mkTFProvider { source = sources.terraform-provider-huaweicloud; };

        azuread = self.lib.mkTFProvider { source = sources.terraform-provider-azuread; };

        azurerm = self.lib.mkTFProvider { source = sources.terraform-provider-azurerm; };

        helm = self.lib.mkTFProvider { source = sources.terraform-provider-helm; };

        kubernetes = self.lib.mkTFProvider { source = sources.terraform-provider-kubernetes; };

        vault = self.lib.mkTFProvider { source = sources.terraform-provider-vault; };

        cloudinit = self.lib.mkTFProvider { source = sources.terraform-provider-cloudinit; };

        # Take from nixpkgs, but keep the old provider-source-address
        keycloak = super.terraform-providers.keycloak.overrideAttrs (old:
          { passthru.provider-source-address = "registry.terraform.io/toolbox/keycloak"; }
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
                 kustomize pre-commit shellcheck
                 envsubst awscli restic azure-cli
                 saml2aws
                 k9s
                 terraform_1 terraform-docs tflint;

  terraform_1_0_0 = builtins.trace "terraform_1_0_0 is deprecated use terraform_1" terraform_1;
  terraform_1_0 = builtins.trace "terraform_1_0 is deprecated use terraform_1" terraform_1;

  ansible = pkgs.ansible_2_10;

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

  kube-rebalancer = pkgs.callPackage ./pkgs/kube-rebalancer { python = pkgs.python39; };

} // optionalAttrs (! pkgs.stdenv.isDarwin) rec {

  openstackclient = pkgs.callPackage ./pkgs/openstack-cli {};

  os = pkgs.callPackage ./pkgs/os { inherit openstackclient; };

}
