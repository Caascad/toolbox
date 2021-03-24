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
  vendorSha256 = "0kh6lljvqd577s19gx0fmfsmx9wm3ikla3jz16lbwwb8ahbqcw1f";
  postInstall = "mv $out/bin/terraform-provider-keycloak{,_v${version}}";

  # Skip the go tests ; they require a running keycloak instance
  doCheck = false;

  patches = [
      (fetchpatch {
        url = "https://patch-diff.githubusercontent.com/raw/mrparkers/terraform-provider-keycloak/pull/501.patch";
        sha256 = "02977789mil6m2km06dpnaqgf5l714idnyizqy337qy051904x6b";
      })
    ];

  meta = with lib; {
    description = "Terraform provider for keycloak";
    homepage = "https://github.com/mrparkers/terraform-provider-keycloak";
    license = licenses.mpl20;
    maintainers = with maintainers; [ eonpatapon ];
  };

  passthru.provider-source-address = "registry.terraform.io/toolbox/keycloak";
}
