{ stdenv
, source
, buildGoModule
, fetchzip
, fetchpatch
}:

buildGoModule rec {
  pname = "terraform-provider-gitlab";
  src = fetchzip {
    inherit (source) url sha256;
  };

  inherit (source) version vendorSha256;

  patches = [
    (fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/gitlabhq/terraform-provider-gitlab/pull/716.diff";
      sha256 =  "1rp63ww2ym0zlfqh20ixis0csqkin6fs11smvzdkbpnsvdz6da8b";
    })
  ];

  postInstall = "mv $out/bin/terraform-provider-gitlab{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/gitlab";
}
