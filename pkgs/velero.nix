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

  vendorSha256 = source.vendorSha256;

  doCheck = false;

  ldflags = ''
      -X github.com/vmware-tanzu/velero/pkg/buildinfo.Version=${source.version}
      -X github.com/vmware-tanzu/velero/pkg/buildinfo.GitSHA=${source.rev}
  '';
}

