{ buildGoModule
, source
, fetchzip
, lib
}:

buildGoModule rec {
  pname = "fly";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };

  vendorSha256 = "1zzb7n54hnl99lsgln9pib2anmzk5zmixga5x68jyrng91axjifb";

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
