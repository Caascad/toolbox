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
  vendorSha256 = "10kvss23a8a6q26a7h1bqc3i0nskm2halsvc9wdv9zf9qsz7zjkp";
  subPackages = [ "cmd/cue" ];
  buildFlagsArray = [
    "-ldflags=-X cuelang.org/go/cmd/cue/cmd.version=${version}"
  ];
}
