{ stdenv
, source
, buildGoModule
}:

buildGoModule rec {
  name = "terraform-provider-k8sraw-${version}";
  version = source.version;
  src = source.outPath;
  modSha256 = "0hlcbv9jybmhlpqyshlcjjr637agkbjmcx7s4dmslh3hha8rdzcj";
  postInstall = "mv $out/bin/terraform-provider-{kubernetes-yaml,k8sraw_v${version}}";

  meta = with stdenv.lib; {
    description = "Terraform provider for kubernetes";
    homepage = "https://github.com/nabancard/terraform-provider-kubernetes-yaml";
    license = licenses.mpl20;
    maintainers = with maintainers; [ lightcode ];
  };
}
