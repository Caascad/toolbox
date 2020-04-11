{ pkgs
, stdenv
, fetchurl
, appimageTools
}:

let

  pname = "jitsi-meet";
  version = "2.0.0b2";
  name = "${pname}-${version}";

  src = fetchurl {
    url = "https://github.com/jitsi/jitsi-meet-electron/releases/download/v2.0.0-beta2/jitsi-meet-x86_64.AppImage";
    sha256 = "00qqa3a2jl2sr3yy04iwaaqy0swf5ai27w6jlrv60ysc7wx7z079";
  };

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
