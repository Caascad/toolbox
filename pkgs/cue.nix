{ buildGoModule
, fetchzip
, source
}:

buildGoModule rec {
  pname = "cue";
  version = source.version;
  src = fetchzip {
      inherit (source) url sha256;
  };
  vendorSha256 = "0xkaabfzqrg0pqdq7ah67yx132508l5kfr9xs98is79732a9a8kr";
  subPackages = [ "cmd/cue" ];
  buildFlagsArray = [
    "-ldflags=-X cuelang.org/go/cmd/cue/cmd.version=${version}"
  ];
}
