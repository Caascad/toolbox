{stdenv, source, fetchurl}:  
stdenv.mkDerivation rec { 
  name="tf";
  version=source.version;
  src = source.outPath;

  meta = with stdenv.lib; {
    description = "wrapper around terraform";
    homepage = "https://github.com/Caascad/tf";
    license = licenses.mit;
    maintainers = with maintainers; [ "bgeneze" ];
  };

  installPhase = ''
    mkdir -p $out/bin
    ls
    pwd
    cp tf $out/bin/
    chmod +x $out/bin/tf
   '';
  }
