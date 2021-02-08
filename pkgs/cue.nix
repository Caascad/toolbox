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
  vendorSha256 = "0drnmf8gfj3k74z5zh0032g5kg3nzji5ji1m3qbxfzisp5cvba7m";
  subPackages = [ "cmd/cue" ];
  buildFlagsArray = [
    "-ldflags=-X cuelang.org/go/cmd/cue/cmd.version=${version}"
  ];
}
