# From https://github.com/NixOS/nixpkgs/pull/73385

{ stdenv
, source
, rustPlatform
}:

with builtins;

rustPlatform.buildRustPackage rec {
  pname = "kubernix";
  version = source.version;
  src = source.outPath;

  doCheck = false;
  cargoSha256 = "02x7pdpnl3p9aly3skc2a2w4xpx4g7yrwgk7m13gsk1p7271x96w";

  meta = with stdenv.lib; {
    description = "Single dependency Kubernetes clusters for local testing, experimenting and development";
    homepage = https://github.com/saschagrunert/kubernix;
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ saschagrunert ];
    platforms = platforms.linux;
  };
}
