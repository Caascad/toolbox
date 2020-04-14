{ pkgs
, stdenv
, fetchurl
, appimageTools
, source
}:

let

  pname = "jitsi-meet";
  name = "${pname}-${version}";
  version = source.version;
  src = source.outPath;

  appimageContents = appimageTools.extractType2 {
    inherit name src;
  };

in appimageTools.wrapType2 {
  inherit name src;

  meta = with stdenv.lib; {
    description = "Jitsi Meet desktop application powered by electron";
    homepage = "https://github.com/jitsi/jitsi-meet-electron";
    license = licenses.asl20;
    maintainers = with maintainers; [ eonpatapon ];
  };

  extraInstallCommands = ''
    mv $out/bin/${name} $out/bin/${pname}
    install -m 444 -D ${appimageContents}/${pname}.desktop $out/share/applications/${pname}.desktop
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}'
    ln -s ${appimageContents}/usr/share/icons $out/share/icons
  '';
}
