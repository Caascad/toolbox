{ stdenv
, source
, buildGo112Module
}:

# Use Go 1.12 because of go mod validation issues
# github.com/prometheus/prometheus@v2.9.2+incompatible: invalid version: +incompatible suffix not allowed: module contains a go.mod file, so semantic import versioning is required
#
# https://github.com/golang/go/issues/34330

buildGo112Module rec {
  name = "terraform-provider-rancher2-${version}";
  version = source.version;
  src = source.outPath;

  modSha256 = "05kk6b1l6bhxr6nla46m7n3whix2i1g15l3p7xpngcfyf56f7l6m";

  postInstall = "mv $out/bin/terraform-provider-rancher2{,_v${version}}";

  meta = with stdenv.lib; {
    description = "Terraform provider for rancher";
    homepage = "https://github.com/terraform-providers/terraform-provider-rancher2";
    license = licenses.mpl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
