{ buildGoModule
, fetchFromGitHub
, source
}:

buildGoModule rec {
  pname = "cue-0.3.0";
  version = "git${builtins.substring 0 6 source.rev}";
  src = fetchFromGitHub {
    owner = source.owner;
    repo = source.repo;
    rev = source.rev;
    sha256 = source.sha256;
  };
  vendorSha256 = "0xdrmwdqpdz7l364ll6kk8kbgsc6hwkjakbz2yrbphm1l7yc8kdp";
  subPackages = [ "cmd/cue" ];
  buildFlagsArray = [
    "-ldflags=-X cuelang.org/go/cmd/cue/cmd.version=0.3.0~${version}"
  ];
}
