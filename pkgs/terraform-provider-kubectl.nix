{ lib
, fetchzip
, source
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-kubectl";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };

  vendorSha256 = "1qrw2mg8ik2n6xlrnbcrgs9zhr9mwh1niv47kzhbp3mxvj5vdskk";
  postInstall = "mv $out/bin/terraform-provider-kubectl{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/kubectl";

  meta = with lib; {
    description = "Terraform provider for kubectl";
    homepage = "https://github.com/gavinbunney/terraform-provider-kubectl";
    license = licenses.mpl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
