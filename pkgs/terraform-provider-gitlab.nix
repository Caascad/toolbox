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
      sha256 = "sha256-Md3JW2gUwROw39FaoCk6IaEZ3LQFc4zjBovMkPsMBIc=";
    })
  ];

  postInstall = "mv $out/bin/terraform-provider-gitlab{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/gitlab";
}
