{ lib
, source
, buildGoModule
, fetchzip
, fetchpatch
}:

buildGoModule rec {
  pname = "terraform-provider-restapi";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };
  vendorSha256 = "1qlnijmniy6i0cx8wclls5cyyvm21vl6gq1mly9pm3x8lkq5i2a2";
  postInstall = "mv $out/bin/terraform-provider-restapi{,_v${version}}";

  meta = with lib; {
    description = "Terraform provider for restapi";
    homepage = "https://github.com/Mastercard/terraform-provider-restapi";
    license = licenses.asl20;
    maintainers = with maintainers; [ "Benjîle" ];
  };

  passthru.provider-source-address = "registry.terraform.io/toolbox/restapi";
}
