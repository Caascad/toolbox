{ stdenv
, source
, buildGoModule
, fetchzip
}:

buildGoModule rec {
  pname = "terraform-provider-aws";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };
  vendorSha256 = source.vendorSha256;

  subPackages = [ "." ];

  doCheck = false;

  postInstall = "mv $out/bin/terraform-provider-aws{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/aws";
}
