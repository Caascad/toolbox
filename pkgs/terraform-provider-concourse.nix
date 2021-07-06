{ stdenv
, source
, buildGoModule
, fetchzip
}:

buildGoModule rec {
  pname = "terraform-provider-concourse";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };
  vendorSha256 = "0zp2iiq6zg9j2br6pk8hb60wf7bkn8x97c4887z7myxcwbjxivgl";

  doCheck = false;
  preBuild = "rm -fr integration";
  postInstall = "mv $out/bin/terraform-provider-concourse{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/concourse";
}
