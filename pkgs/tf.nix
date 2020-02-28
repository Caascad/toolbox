{
  stdenv, 
  source,
  makeWrapper,
  terraform
}:
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
  buildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp tf $out/bin/
    chmod +x $out/bin/tf
    wrapProgram $out/bin/tf $wrapperfile --prefix PATH ":" ${terraform}/bin
   '';
  }
