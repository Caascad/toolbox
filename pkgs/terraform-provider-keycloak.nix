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
        sha256 = "1lcp2c5xf8p689a6m87wdxdxy0xwygkxixxz3sp2667lzbd6r5l4";
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
