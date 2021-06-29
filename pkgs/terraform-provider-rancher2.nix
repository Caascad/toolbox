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

  vendorSha256 = "16vnn4hfs72nnc2l2kzbhnnbh0r9hv8mrpawgq2hf4klm93ywgk0";
  postInstall = "mv $out/bin/terraform-provider-rancher2{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/rancher2";

  meta = with lib; {
    description = "Terraform provider for rancher2";
    homepage = "https://github.com/terraform-providers/terraform-provider-rancher2";
    license = licenses.mpl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
