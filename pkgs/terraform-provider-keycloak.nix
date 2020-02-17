{ stdenv
, source
, buildGoModule
}:

buildGoModule rec {
  name = "terraform-provider-keycloak-${version}";
  version = source.version;
  src = source.outPath;
  modSha256 = "1wja73dknbyxpqbz6k2mbi9zrfdplfmzgcki59z5bz346gjrii6j";
  postInstall = "mv $out/bin/terraform-provider-keycloak{,_v${version}}";

  meta = with stdenv.lib; {
    description = "Terraform provider for keycloak";
    homepage = "https://github.com/mrparkers/terraform-provider-keycloak";
    license = licenses.mpl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
