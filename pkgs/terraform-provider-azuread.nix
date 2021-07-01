{ stdenv
, source
, buildGoModule
, fetchzip
}:

buildGoModule rec {
  pname = "terraform-provider-azuread";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };
  vendorSha256 = null;

  subPackages = [ "." ];

  doCheck = false;

  postInstall = "mv $out/bin/terraform-provider-azuread{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/azuread";
}
