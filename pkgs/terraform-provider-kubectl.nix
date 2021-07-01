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

  vendorSha256 = "13v83agxhpd56qg1sdk8dkyi6ipac997cgl5y2w7imdbrn84qd23";
  postInstall = "mv $out/bin/terraform-provider-kubectl{,_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/kubectl";

  meta = with lib; {
    description = "Terraform provider for kubectl";
    homepage = "https://github.com/gavinbunney/terraform-provider-kubectl";
    license = licenses.mpl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
