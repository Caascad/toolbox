{ buildGoModule
, fetchzip
, source
, lib
}:

buildGoModule rec {
  pname = "cue";
  version = source.version;
  src = fetchzip {
      inherit (source) url sha256;
  };
  subPackages = [ "cmd/cue" ];
  ldflags = [ "-X cuelang.org/go/cmd/cue/cmd.version=${version}" ];
  # vendorHash = lib.fakeHash;
  vendorHash = "sha256-z7OLsIN+8N17ly4le4a4ziPesVIMVe+fFN4XgdAJTcI=";
}
