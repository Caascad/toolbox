{ buildGoModule
, fetchzip
, source
}:

buildGoModule rec {
  pname = "cue";
  version = source.version;
  vendorSha256 = source.vendorSha256;
  src = fetchzip {
      inherit (source) url sha256;
  };
  subPackages = [ "cmd/cue" ];
  ldflags = "-X cuelang.org/go/cmd/cue/cmd.version=${version}";
}
