{ stdenv
, prometheus-alertmanager
}:

stdenv.mkDerivation {
  pname = "amtool";
  version = prometheus-alertmanager.version;

  unpackPhase = ":";
  installPhase = ''
    install -m755 -D ${prometheus-alertmanager}/bin/amtool $out/bin/amtool
  '';

  meta = with stdenv.lib; {
    description = "Alertmanager CLI";
    homepage = "https://github.com/prometheus/alertmanager";
    license = licenses.asl20;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
