{ lib
, fetchzip
, source
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-rancher2";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };

  vendorSha256 = source.vendorSha256;
  postInstall = "mv $out/bin/terraform-provider-rancher2{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/rancher2";

  meta = with lib; {
    description = "Terraform provider for rancher2";
    homepage = "https://github.com/terraform-providers/terraform-provider-rancher2";
    license = licenses.mpl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
