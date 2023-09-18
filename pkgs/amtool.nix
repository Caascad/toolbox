{ stdenv
, lib
, prometheus-alertmanager
}:
stdenv.mkDerivation {
  pname = "amtool";
  version = prometheus-alertmanager.version;
  unpackPhase = ":";

  installPhase = ''
    mkdir -p $out/bin
    cp ${prometheus-alertmanager.outPath}/bin/amtool $out/bin
  '';

  meta = with lib; {
    description = "Tooling for the Alertmanager alerting system.";
    homepage = "https://prometheus.io";
    license = licenses.asl20;
    maintainers = with maintainers; [ bgeneze ];
  };
}
