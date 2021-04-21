{ stdenv
}:

{

  stats_exporter = stdenv.mkDerivation {
    pname = "ansible-stats-exporter";
    version = "1.0.0";

    unpackPhase = ":";
    installPhase = ''
      mkdir -p $out/callback
      cp ${./stats_exporter.py} $out/callback/stats_exporter.py
    '';
  };

}
