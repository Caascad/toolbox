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
  vendorSha256 = "1viy483yr89f4a8xgx5r8bvgx0xhcn628glmfkllgrzz53fn2w1a";

  subPackages = [ "." ];

  doCheck = false;

  postInstall = "mv $out/bin/terraform-provider-aws{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/aws";
}
