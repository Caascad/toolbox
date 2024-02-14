{ stdenv
, lib
, tflint-ruleset-aws
}:
stdenv.mkDerivation rec {
  pname = "tflint-ruleset-aws";
  version = tflint-ruleset-aws.version;
  unpackPhase = ":";

  installPhase = ''
    mkdir -p $out/bin
    cp ${tflint-ruleset-aws}/github.com/terraform-linters/${pname}/${version}/* $out/bin
  '';
  meta = tflint-ruleset-aws.meta;
}
