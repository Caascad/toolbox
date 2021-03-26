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
  vendorSha256 = "16kv76nph8sf7c6ma9w8qsdisq8k6aimki1ni6vlwr9gvfbx47si";

  subPackages = [ "." ];

  doCheck = false;

  postInstall = "mv $out/bin/terraform-provider-aws{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/aws";
}
