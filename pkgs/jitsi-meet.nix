{ pkgs
, stdenv
, fetchurl
, appimageTools
}:

let

  name = "jitsi-meet-2.0.0b2";

in (appimageTools.wrapType2 rec {
  inherit name;
  src = fetchurl {
    url = "https://github.com/jitsi/jitsi-meet-electron/releases/download/v2.0.0-beta2/jitsi-meet-x86_64.AppImage";
    sha256 = "00qqa3a2jl2sr3yy04iwaaqy0swf5ai27w6jlrv60ysc7wx7z079";
  };
}).overrideAttrs (old: {
  meta = with stdenv.lib; {
    description = "Jitsi Meet desktop application powered by electron";
    homepage = "https://github.com/jitsi/jitsi-meet-electron";
    license = licenses.asl20;
    maintainers = with maintainers; [ eonpatapon ];
  };

  buildCommand = old.buildCommand + ''
    mkdir -p $out/share/applications
    cat <<EOF > $out/share/applications/jitsi-meet.desktop
[Desktop Entry]
Name=Jitsi Meet
Comment=Jitsi Meet desktop application powered by electron
Exec=${name}
Icon=camera-web
Terminal=false
Type=Application
Categories=Network;
EOF
  '';

})
