{ stdenv
, source
, buildGoModule
, fetchzip
, fetchpatch
}:

buildGoModule rec {
  pname = "terraform-provider-aws";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };
  vendorSha256 = "082g2warcgkxn37g0shbfqml9j5mgw7zi5wnqm9im7jigm7dc76r";

  subPackages = [ "." ];

  doCheck = false;

  postInstall = "mv $out/bin/terraform-provider-aws{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/aws";
}
