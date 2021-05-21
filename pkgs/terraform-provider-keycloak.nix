{ lib
, source
, buildGoModule
, fetchzip
, fetchpatch
}:

buildGoModule rec {
  pname = "terraform-provider-keycloak";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };
  vendorSha256 = "0il4rvwa23zghrq0b8qrzgxyjy0211v9z2a4ln2xmlhcz0105zg8";
  postInstall = "mv $out/bin/terraform-provider-keycloak{,_v${version}}";

  # Skip the go tests ; they require a running keycloak instance
  doCheck = false;

  meta = with lib; {
    description = "Terraform provider for keycloak";
    homepage = "https://github.com/mrparkers/terraform-provider-keycloak";
    license = licenses.mpl20;
    maintainers = with maintainers; [ eonpatapon ];
  };

  passthru.provider-source-address = "registry.terraform.io/toolbox/keycloak";
}
