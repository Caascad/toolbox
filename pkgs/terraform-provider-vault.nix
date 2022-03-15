{ stdenv
, source
, buildGoModule
, fetchzip
}:

buildGoModule rec {
  pname = "terraform-provider-vault";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };
  vendorSha256 = source.vendorSha256;

  postBuild = "mv ../go/bin/${pname}{,_v${version}}";

  doCheck = false;

  passthru.provider-source-address = "registry.terraform.io/toolbox/vault";
}
