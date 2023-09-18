{ sources ? import ./nix/sources.nix
, nixpkgs ? sources.nixpkgs
, nixpkgs-old ? sources.nixpkgs-old
}:

let

  # See: https://github.com/NixOS/nixpkgs/issues/193657
  pkgs-poetry = import sources.nixpkgs-poetry {};

  terraform-providers-list = ["aws" "rancher2" "kubectl" "gitlab" "flexibleengine" "huaweicloud" "azuread" "azurerm" "helm" "kubernetes" "cloudinit" "vault" "keycloak"
    "controltower" "concourse" "harbor" "privx"
  ];

  pkgs = import nixpkgs {
    overlays = [(self: super: {

      kompose = super.kompose.override {
        # Build is failing on Darwin with Go 1.18
        buildGoModule = pkgs.buildGoModule;
      };

      lib = super.lib // {

        # Taken and adapted from nixpkgs/pkgs/applications/networking/cluster/terraform-providers/default.nix
        mkTFProvider = super.lib.makeOverridable
          ({ source
           , deleteVendor ? false
           , proxyVendor ? false
           , patches ? []
           , buildGoModule ? pkgs.buildGo119Module
           }:
            let
              provider-name = with super.lib; head (reverseList (splitString "-" source.repo));
              provider-source-address =  "registry.terraform.io/toolbox/${provider-name}";
            in buildGoModule rec {
              pname = source.repo;
              inherit (source) version;
              vendorSha256 = if source ? "vendorSha256" then source.vendorSha256 else null;
              inherit deleteVendor proxyVendor patches;
              subPackages = [ "." ];
              doCheck = false;
              # https://github.com/hashicorp/terraform-provider-scaffolding/blob/a8ac8375a7082befe55b71c8cbb048493dd220c2/.goreleaser.yml
              # goreleaser (used for builds distributed via terraform registry) requires that CGO is disabled
              CGO_ENABLED = 0;
              ldflags = [ "-s" "-w" "-X main.version=${version}" ];
              src = pkgs.fetchzip {
                inherit (source) url sha256;
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
        controltower = self.lib.mkTFProvider { source = sources.terraform-provider-controltower; };
        concourse = self.lib.mkTFProvider { source = sources.terraform-provider-concourse; };
        harbor = self.lib.mkTFProvider { source = sources.terraform-provider-harbor; };
        privx = self.lib.mkTFProvider { source = sources.terraform-provider-privx; };
      };

    })];
  };


in

with pkgs.lib;

rec {

  # Expose all nixpkgs packages in `pkgs` attribute
  inherit pkgs;

  inherit (pkgs) nix 
                 kapp kubectl gopass stern kubectx k9s
                 shellcheck go gnupg curl direnv yq jq vault docker-compose cfssl kompose envsubst cue
                 saml2aws awscli restic azure-cli
                 terraform_1 terraform-docs tflint ansible
                 git pre-commit;

  terraform_1_0_0 = builtins.trace "terraform_1_0_0 is deprecated use terraform_1" terraform_1;
  terraform_1_0 = builtins.trace "terraform_1_0 is deprecated use terraform_1" terraform_1;

  amtool = pkgs.callPackage ./pkgs/amtool.nix {};
  amtool-caascad = pkgs.callPackage ./pkgs/amtool-caascad { inherit amtool; };

  helm = pkgs.kubernetes-helm;

  # Expose providers that don't come from nixpkgs (so that we can push them in the cache)
  terraform-providers = filterAttrs (name: drv:
    if (builtins.tryEval drv).success && (builtins.elem name terraform-providers-list) then true else false) pkgs.terraform-providers;

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

  vault-token-helper = pkgs.callPackage ./pkgs/vault-token-helper.nix {
    source = sources.vault-token-helper;
    buildGoModule = pkgs.buildGo118Module;
  };

  velero = pkgs.callPackage ./pkgs/velero.nix
    { source = sources.velero; };

  rancher-cli = pkgs.callPackage ./pkgs/rancher-cli.nix {
    source = sources.rancher-cli;
    buildGoModule = pkgs.buildGo118Module;
  };

  tflint-ruleset-aws = pkgs.callPackage ./pkgs/tflint-ruleset-aws.nix {
    source = sources.tflint-ruleset-aws;
    buildGoModule = pkgs.buildGo120Module;
  };

  promtool = pkgs.callPackage ./pkgs/promtool.nix {};

  sd = import sources.sd.outPath { inherit pkgs; };

  # TODO: nixpkgs locked for poetry https://github.com/NixOS/nixpkgs/issues/193657
  rswitch = import sources.rswitch.outPath {
    pkgs = pkgs-poetry;
  };

  get-rancher-creds = (import sources.conformity-tooling { inherit pkgs;}).getranchercreds;
  checkmetrics = (import sources.conformity-tooling {inherit pkgs; }).checkmetrics;

  kube-rebalancer = pkgs.callPackage ./pkgs/kube-rebalancer { python = pkgs.python3; };

} // optionalAttrs (! pkgs.stdenv.isDarwin) rec {

  # TODO: nixpkgs locked for poetry https://github.com/NixOS/nixpkgs/issues/193657
  openstackclient = pkgs.callPackage ./pkgs/openstack-cli {
    pkgs = pkgs-poetry;
  };

  os = pkgs.callPackage ./pkgs/os { inherit openstackclient; };

  inherit (pkgs) open-policy-agent;
}
