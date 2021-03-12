{ stdenv
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

  vendorSha256 = "0v8xl9lg6gqxq94a56gqfm3g796qgg21b0rf42gkvl5ckqvmnxqj";
  postInstall = "mv $out/bin/terraform-provider-rancher2{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/rancher2";

  meta = with stdenv.lib; {
    description = "Terraform provider for rancher2";
    homepage = "https://github.com/terraform-providers/terraform-provider-rancher2";
    license = licenses.mpl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
