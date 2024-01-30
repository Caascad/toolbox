{
  pkgs
, lib
}:

let

  deps = with pkgs; lib.makeBinPath [ curl jq ];

in pkgs.stdenv.mkDerivation rec {
  pname = "discovery";
  version = "1.0.7";

  unpackPhase = "true"; ## string parsed to get the binary used to unpack i.e. the source won't be unpacked
  buildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    install -m755 -D ${./sd.sh} $out/bin/sd
    wrapProgram $out/bin/sd --prefix PATH ":" ${deps}
  '';

  meta = with lib; {
    description = "Service discovery";
    homepage = "https://github.com/Caascad/toolbox";
    license = licenses.mit;
    maintainers = with maintainers; [ "Benjile" ];
  };
}
