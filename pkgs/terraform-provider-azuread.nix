{ stdenv
, source
, buildGoModule
, fetchzip
, fetchpatch
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

  patches = [
    (fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/hashicorp/terraform-provider-azuread/pull/401.patch";
      sha256 = "1a20mpq6k37bdjf3szgwd1h01dr20i9isy4dq591102014cqdhzh";
    })
  ];

  postInstall = "mv $out/bin/terraform-provider-azuread{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/azuread";
}
