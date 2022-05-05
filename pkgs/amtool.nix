{ lib
, go
, buildGoModule
, fetchFromGitHub
, installShellFiles
, source
}:

buildGoModule rec {
  pname = "amtool";
  version = source.version;

  src = fetchFromGitHub {
    rev = "v${version}";
    owner = source.owner;
    repo = source.repo;
    sha256 = source.sha256;
  };

  vendorSha256 = source.vendorSha256;

  subPackages = [ "cmd/amtool" ];

  ldflags = let t = "github.com/prometheus/common/version"; in [
    "-X ${t}.Version=${version}"
    "-X ${t}.Revision=${src.rev}"
    "-X ${t}.Branch=unknown"
    "-X ${t}.BuildUser=CaascadTeam"
    "-X ${t}.BuildDate=unknown"
    "-X ${t}.GoVersion=${lib.getVersion go}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    $out/bin/amtool --completion-script-bash > amtool.bash
    installShellCompletion amtool.bash
    $out/bin/amtool --completion-script-zsh > amtool.zsh
    installShellCompletion amtool.zsh
  '';

  meta = with lib; {
    description = "Alert dispatcher for the Prometheus monitoring system";
    homepage = "https://github.com/prometheus/alertmanager";
    license = licenses.asl20;
    maintainers = with maintainers; [ "ngc104" "jpduthilleul" ];
    platforms = platforms.unix;
  };
}
