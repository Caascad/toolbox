{ buildGoModule
, fetchFromGitHub
, source
, lib
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

  vendorHash = "sha256-l8srlzoCcBZFOwVs7veQ1RvqWRIqQAaZLM/2CbNHN50=";

  doCheck = false;

  ldflags = [ 
    "-X github.com/vmware-tanzu/velero/pkg/buildinfo.Version=v${source.version}"
    "-X github.com/vmware-tanzu/velero/pkg/buildinfo.GitSHA=${source.rev}"
  ];
}

