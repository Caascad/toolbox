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
  vendorSha256 = "136igsvw1x96rf8vlpzw325y0pfjxypy3dbc8wji3my9s5w9267h";
  subPackages = [ "cmd/cue" ];
  buildFlagsArray = [
    "-ldflags=-X cuelang.org/go/cmd/cue/cmd.version=0.3.0~${version}"
  ];
}
