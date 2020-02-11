{ stdenv
, source
, buildGoModule
}:

buildGoModule rec {
  name = "terraform-provider-keycloak-${version}";
  version = source.version;
  src = source.outPath;
  modSha256 = "18kq7kb7fh6njvpra4ahkhdgsg4hy7vv9q51wg9x64rzxjxa4vq0";
  postInstall = "mv $out/bin/terraform-provider-keycloak{,_v${version}}";

  meta = with stdenv.lib; {
    description = "Terraform provider for keycloak";
    homepage = "https://github.com/mrparkers/terraform-provider-keycloak";
    license = licenses.mpl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
