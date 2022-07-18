{ buildGoModule
, fetchFromGitHub
, lib
, source
}:

buildGoModule rec {
  pname = "rancher-cli";
  version = source.version;

  src = fetchFromGitHub {
    owner = source.owner;
    repo = source.repo;
    rev = "v${version}";
    sha256 = source.sha256;
  };

  vendorSha256 = source.vendorSha256;

  postInstall = ''
      mv $out/bin/cli $out/bin/rancher
    '';

  CGO_ENABLED = 0;

  ldflags = [
      "-w" "-s"
      "-extldflags '-static'"
      "-X main.VERSION=${source.version}"
  ];

  meta = with lib; {
    description = "Rancher CLI to interact with Rancher Server";
    homepage = "https://rancher.com/";
    license = licenses.asl20;
    maintainers = [ "xmaillard" ];
  };
}

