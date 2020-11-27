{ stdenv
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

  vendorSha256 = "03x2l6bdjmc1sy58xxkbm5akmzgyrmbq0d3ghyk2v1m1mj9gbj40";
  postInstall = "mv $out/bin/terraform-provider-{kubernetes-yaml,k8sraw_v${version}}";

  passthru.provider-source-address = "registry.terraform.io/toolbox/k8sraw";

  meta = with stdenv.lib; {
    description = "Terraform provider for kubernetes";
    homepage = "https://github.com/nabancard/terraform-provider-kubernetes-yaml";
    license = licenses.mpl20;
    maintainers = with maintainers; [ lightcode ];
  };
}
