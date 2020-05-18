{ stdenv
, source
, buildGoModule
}:

buildGoModule rec {
  name = "terraform-provider-keycloak-${version}";
  version = source.version;
  src = source.outPath;
  vendorSha256 = "12iary7p5qsbl4xdhfd1wh92mvf2fiylnb3m1d3m7cdcn32rfimq";
  postInstall = "mv $out/bin/terraform-provider-keycloak{,_v${version}}";

  meta = with stdenv.lib; {
    description = "Terraform provider for keycloak";
    homepage = "https://github.com/mrparkers/terraform-provider-keycloak";
    license = licenses.mpl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
