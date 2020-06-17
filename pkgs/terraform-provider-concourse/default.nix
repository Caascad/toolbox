{ stdenv
, fetchzip
, source
, buildGoPackage
}:

buildGoPackage rec {
  name = "terraform-provider-concourse-${version}";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };

  goPackagePath = "github.com/alphagov/terraform-provider-concourse";
  # To fix go mod download error:
  # github.com/concourse/concourse@v5.5.1+incompatible: invalid version: +incompatible suffix
  # not allowed: module contains a go.mod file, so semantic import versioning is required
  # Do:
  # go mod edit -require=github.com/concourse/concourse@4adfcb19cc9dfb22db861608ef8b7003e01ce1dc # v5.8.0 commit
  # go mod tidy
  # Then generate deps.nix with vgo2nix -keep-going (master branch)
  goDeps = ./deps.nix;

  # Integration tests don't build
  preBuild = ''
    rm -rf $NIX_BUILD_TOP/go/src/github.com/alphagov/terraform-provider-concourse/integration
  '';

  postInstall = ''
    mv $out/bin/terraform-provider-concourse{,_v${version}}
  '';

  meta = with stdenv.lib; {
    description = "Terraform provider for Concourse";
    homepage = "https://github.com/alphagov/terraform-provider-concourse";
    license = licenses.mit;
    maintainers = with maintainers; [ eonpatapon ];
  };

}
