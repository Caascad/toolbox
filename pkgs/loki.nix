{ buildGoModule
, fetchFromGitHub
, source
}:

buildGoModule rec {
  pname = "logcli";
  version = source.version;
  subPackages = [ "cmd/logcli" ];
  src = fetchFromGitHub {
    owner = source.owner;
    repo = source.repo;
    rev = "v${version}";
    sha256 = source.sha256;
  };
  vendorHash= null;
}

