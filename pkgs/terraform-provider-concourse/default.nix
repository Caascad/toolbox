{ stdenv
, fetchzip
, source
, buildGoModule
}:

buildGoModule rec {
  pname = "terraform-provider-concourse";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };

  vendorSha256 = "0azp1q7xavispqq2ib0k8n5kl0f40bnmj3c7vi8qghscl5al6psw";

  # Integration tests don't build
  preBuild = ''
    rm -rf integration
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
