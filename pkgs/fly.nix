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

  fly_7_3_2 = fly_go {
    source = sources.concourse_7_3_2;
  };

  fly_6_4_1 = fly_go {
    source = sources.concourse_6_4_1;
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

    function current_target() {
      if [[ -e "$HOME/.fly-current-target" ]]; then
        cat "$HOME/.fly-current-target"
      fi
    }

    function get_api_url() {
      local target="$1"
      if [[ -f "$HOME/.flyrc" ]]; then
        ${yq}/bin/yq -M -r --arg target "$target" '.targets[$target].api' ~/.flyrc
      fi
    }

    ARGS=( "$@" )

    TARGET=""
    while [ "$#" -gt 0 ]; do
      if [[ "$1" == "--target" ]] || [[ "$1" == "-t" ]]; then
        TARGET="$2"
        shift
      fi
      shift
    done

    if [[ -z "$TARGET" ]]; then
      TARGET="$(current_target)"
    fi

    API_URL="$(get_api_url $TARGET)"
    if [[ -n "$API_URL" ]] && [[ "$API_URL" != "null" ]]; then
      RESP="$(${curl}/bin/curl -s --fail --connect-timeout 10 "$API_URL/api/v1/info")" || err=$?
      if [[ "$err" -eq 0 ]]; then
        VERSION="$(${yq}/bin/yq -r -M .version <<< "$RESP")"
      else
        echo >&2 "[fly-wrapper-nix] Failed to fetch concourse version, curl returns error code $err."
      fi
    fi

    case "$VERSION" in
      7.3.2) FLY_BIN="${fly_7_3_2}/bin" ;;
          *) FLY_BIN="${fly_6_4_1}/bin" ;;
    esac

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
      ${fly_6_4_1}/bin/fly completion --shell bash > $out/share/bash-completion/completions/fly
  '';

  meta = with lib; {
    description = "Fly wrapper with automatic concourse version selection";
    homepage = "https://github.com/Caascad/fly-wrapper";
    license = licenses.mpl20;
    maintainers = with maintainers; [ "lightcode" ];
  };
}
