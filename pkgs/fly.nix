{ pkgs
, lib
, stdenv
, buildGoModule
, fetchzip
, sources
, yq
, curl
}:

let

  fly-wrapper = import sources.fly-wrapper.outPath { inherit pkgs; };

  fly_7_6_0 = fly_go {
    source = sources.concourse_7_6_0;
  };

  fly_go = {source}: buildGoModule rec {
    pname = "fly";
    version = source.version;
    src = fetchzip {
      inherit (source) url sha256;
    };

    vendorSha256 = source.vendorSha256;

    subPackages = [ "fly" ];

    ldflags = "-X github.com/concourse/concourse.Version=${source.version}";

    postInstall = ''
      mkdir -p $out/share/bash-completion/completions
      $out/bin/fly completion --shell bash > $out/share/bash-completion/completions/fly
    '';

    meta = with lib; {
      description = "A command line interface to Concourse CI";
      homepage = https://concourse-ci.org;
      license = licenses.asl20;
      maintainers = with maintainers; [ ivanbrennan ];
    };
  };

  entrypoint = ''
    #!${pkgs.runtimeShell}
    set -eo pipefail

    FLY_BIN="${fly_7_6_0}/bin"
    export PATH="$FLY_BIN:$PATH"
    ${fly-wrapper}/bin/fly-wrapper "''${ARGS[@]}"
  '';

in stdenv.mkDerivation {
  pname = "fly";
  version = fly-wrapper.version;

  unpackPhase = ":";

  inherit entrypoint;
  passAsFile = [ "entrypoint" ];
  installPhase = ''
      mkdir -p $out/bin
      cat "$entrypointPath" > $out/bin/fly
      chmod 755 $out/bin/fly
      mkdir -p $out/share/bash-completion/completions
      ${fly_7_6_0}/bin/fly completion --shell bash > $out/share/bash-completion/completions/fly
  '';

  meta = with lib; {
    description = "Fly wrapper with automatic concourse version selection";
    homepage = "https://github.com/Caascad/fly-wrapper";
    license = licenses.mpl20;
    maintainers = with maintainers; [ "lightcode" ];
  };
}
