{ stdenv
, source
, buildGoPackage
}:

buildGoPackage rec {
  pname = "kwt";
  version = source.version;
  src = source.outPath;

  goPackagePath = "github.com/k14s/kwt";
  subPackages = [ "cmd/kwt" ];

  patches = [
    ./kwt-ipv4dns.patch
    ./kwt-srvdns.patch
  ];

  meta = with stdenv.lib; {
    description = "Kubernetes Workstation Tools CLI";
    homepage = "https://github.com/k14s/kwt";
    license = licenses.asl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
