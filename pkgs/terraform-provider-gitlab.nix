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

  postInstall = "mv $out/bin/terraform-provider-gitlab{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/gitlab";

  subPackages = [ "." ];

}
