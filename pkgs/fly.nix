{ buildGoModule, source, lib }:

buildGoModule rec {
  pname = "fly";
  version = source.version;
  src = source.outPath;

  vendorSha256 = "14wwspp8x6i4ry23bz8b08mfyzrwc9m7clrylxzr8j67yhg5kw6v";

  subPackages = [ "fly" ];

  buildFlagsArray = ''
    -ldflags=
      -X github.com/concourse/concourse.Version=${source.version}
  '';

  meta = with lib; {
    description = "A command line interface to Concourse CI";
    homepage = https://concourse-ci.org;
    license = licenses.asl20;
    maintainers = with maintainers; [ ivanbrennan ];
  };
}
