{ lib
, fetchzip
, source
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-k8sraw";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };

  vendorSha256 = source.vendorSha256;
  postInstall = "mv $out/bin/terraform-provider-{kubernetes-yaml,k8sraw_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/k8sraw";

  meta = with lib; {
    description = "Terraform provider for kubernetes";
    homepage = "https://github.com/nabancard/terraform-provider-kubernetes-yaml";
    license = licenses.mpl20;
    maintainers = with maintainers; [ "lightcode" ];
  };
}
