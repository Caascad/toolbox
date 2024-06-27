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
  vendorHash = "sha256-Eq51sydt2eu3pSCRjepvxpU01T0vr0axx9XEk34db28=";
}
