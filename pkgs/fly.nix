{ pkgs
, stdenv
, lib
, buildGoModule
, fetchzip
, sources
, yq
, curl
}:

let

  fly-wrapper = import sources.fly-wrapper.outPath { inherit pkgs; };

  fly_5_8_0 = fly_go {
    source = sources.concourse_5_8_0;
    goVendorSha256 = "1zzb7n54hnl99lsgln9pib2anmzk5zmixga5x68jyrng91axjifb";
  };

  fly_6_4_1 = fly_go {
    source = sources.concourse_6_4_1;
    goVendorSha256 = "0nv9q3j9cja8c6d7ac8fzb8zf82zz1z77f8cxvn3vxjki7fhlavm";
  };

  fly_go = {source, goVendorSha256}: buildGoModule rec {
    pname = "fly";
    version = source.version;
    src = fetchzip {
      inherit (source) url sha256;
    };

    vendorSha256 = goVendorSha256;

    subPackages = [ "fly" ];

    buildFlagsArray = ''
      -ldflags=
        -X github.com/concourse/concourse.Version=${source.version}
    '';

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
      ${yq}/bin/yq -M -r --arg target "$target" '.targets[$target].api' ~/.flyrc
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
      6.4.1) FLY_BIN="${fly_6_4_1}/bin" ;;
          *) FLY_BIN="${fly_5_8_0}/bin" ;;
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

  meta = with stdenv.lib; {
    description = "Fly wrapper with automatic concourse version selection";
    homepage = "https://github.com/Caascad/fly-wrapper";
    license = licenses.mpl20;
    maintainers = with maintainers; [ "lightcode" ];
  };
}
