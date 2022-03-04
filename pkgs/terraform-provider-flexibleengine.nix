{ stdenv
, source
, buildGoModule
, fetchzip
, fetchpatch
}:

buildGoModule rec {
  pname = "terraform-provider-flexibleengine";
  src = fetchzip {
    inherit (source) url sha256;
  };

  inherit (source) version;

  vendorSha256 = null;

  postInstall = "mv $out/bin/terraform-provider-flexibleengine{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/flexibleengine";
}
