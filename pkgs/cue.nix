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
  subPackages = [ "cmd/cue" ];
  buildFlagsArray = [
    "-ldflags=-X cuelang.org/go/cmd/cue/cmd.version=${version}"
  ];
}
