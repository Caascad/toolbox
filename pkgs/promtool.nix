{ stdenv
, lib
, prometheus
}:
stdenv.mkDerivation {
  pname = "promtool";
  version = prometheus.version;
  unpackPhase = ":";

  installPhase = ''
    mkdir -p $out/bin
    cp ${prometheus.cli}/bin/promtool $out/bin
  '';

  meta = with lib; {
    description = "Tooling for the Prometheus monitoring system.";
    homepage = "https://prometheus.io";
    license = licenses.asl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
