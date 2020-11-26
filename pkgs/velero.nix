{ buildGoModule
, fetchFromGitHub
, source
}:

buildGoModule rec {
  pname = "velero";
  version = source.version;
  src = fetchFromGitHub {
    owner = source.owner;
    repo = source.repo;
    rev = "v${version}";
    sha256 = source.sha256;
  };
  vendorSha256 = "1scggvs88c80iwqalm3wrhq8vi58m7hj7ckb0c4rdppqbx4mad48";
}

