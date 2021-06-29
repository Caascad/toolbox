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
  vendorSha256 = "0azp1q7xavispqq2ib0k8n5kl0f40bnmj3c7vi8qghscl5al6psw";

  doCheck = false;
  preBuild = "rm -fr integration";
  postInstall = "mv $out/bin/terraform-provider-concourse{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/concourse";
}
