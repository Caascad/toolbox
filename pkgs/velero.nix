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

  vendorSha256 = "0jw20i3qb8rywf2xwk89b02n2kfgzjrrx4gwlg82f24wmkkqd080";

  doCheck = false;

  buildFlagsArray = ''
    -ldflags=
      -X github.com/vmware-tanzu/velero/pkg/buildinfo.Version=${source.version}
      -X github.com/vmware-tanzu/velero/pkg/buildinfo.GitSHA=${source.rev}
  '';
}

