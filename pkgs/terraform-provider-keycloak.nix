{ stdenv
, source
, buildGoModule
}:

buildGoModule rec {
  name = "terraform-provider-keycloak-${version}";
  version = source.version;
  src = source.outPath;
  modSha256 = "1cinmkpqpcf5whdrl39zbshlxjapgqn46zn6gx41yg3y1bf3kxl8";
  postInstall = "mv $out/bin/terraform-provider-keycloak{,_v${version}}";

  meta = with stdenv.lib; {
    description = "Terraform provider for keycloak";
    homepage = "https://github.com/mrparkers/terraform-provider-keycloak";
    license = licenses.mpl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
