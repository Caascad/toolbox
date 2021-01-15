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

  vendorSha256 = "1izl7z689jf3i3wax7rfpk0jjly7nsi7vzasy1j9v5cwjy2d5z4v";

  doCheck = false;

  buildFlagsArray = ''
    -ldflags=
      -X github.com/vmware-tanzu/velero/pkg/buildinfo.Version=${source.version}
      -X github.com/vmware-tanzu/velero/pkg/buildinfo.GitSHA=${source.rev}
  '';
}

