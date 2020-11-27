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
  vendorSha256 = null;

  doCheck = false;

  postInstall = "mv $out/bin/terraform-provider-aws{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/aws";
}
