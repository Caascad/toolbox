{ stdenv
, source
, buildGoModule
}:

buildGoModule rec {
  name = "terraform-provider-k8sraw-${version}";
  version = source.version;
  src = source.outPath;
  vendorSha256 = "03x2l6bdjmc1sy58xxkbm5akmzgyrmbq0d3ghyk2v1m1mj9gbj40";
  postInstall = "mv $out/bin/terraform-provider-{kubernetes-yaml,k8sraw_v${version}}";

  meta = with stdenv.lib; {
    description = "Terraform provider for kubernetes";
    homepage = "https://github.com/nabancard/terraform-provider-kubernetes-yaml";
    license = licenses.mpl20;
    maintainers = with maintainers; [ lightcode ];
  };
}
