{ stdenv
, fetchzip
, source
, buildGoPackage
}:

buildGoPackage rec {
  name = "terraform-provider-rancher2-${version}";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };

  goPackagePath = "github.com/terraform-providers/terraform-provider-rancher2";

  postInstall = "mv $out/bin/terraform-provider-rancher2{,_v${version}}";

  meta = with stdenv.lib; {
    description = "Terraform provider for rancher";
    homepage = "https://github.com/terraform-providers/terraform-provider-rancher2";
    license = licenses.mpl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
