{ stdenv
, fetchzip
, sources
, pkgs
, makeWrapper
}:
with pkgs;
rec {
  plugins = {
    kubectl-node-shell = callPackage ./scripts.nix {source = sources.kubectl-node-shell; cmdName = "kubectl-node_shell";};
    kubectl-spy        = callPackage ./scripts.nix {source = sources.kubespy; cmdName = "kubespy"; outCmdName = "kubectl-spy";};

    kubectl-ctx        = kubectx.overrideAttrs (old: {
      installPhase = old.installPhase + ''
        ln -s $out/bin/kubectx $out/bin/kubectl-ctx
        ln -s $out/bin/kubens  $out/bin/kubectl-ns
      '';
    });
    kubectl-tail =  buildGoModule rec {
      pname = "kail";
      version = sources.kail.version;
      postInstall = ''
        ln -s $out/bin/kail $out/bin/kubectl-tail
      ''
      ;
      src = fetchFromGitHub {
        owner = sources.kail.owner;
        repo = sources.kail.repo;
        rev = "v${version}";
        sha256 = sources.kail.sha256;
        };
      vendorSha256 = "1d8k65g1sa0nl34vzg1ac51cynlpfvrbpdkcb7n5v1ab09q9lp4x";
      subPackages = ["cmd/kail/"];
      };
  
    kubectl-sniff =  buildGoModule rec {
      pname = "ksniff";
      version = sources.ksniff.version;
      src = fetchFromGitHub {
        owner = sources.ksniff.owner;
        repo = sources.ksniff.repo;
        rev = "v${version}";
        sha256 = sources.ksniff.sha256;
        };
      vendorSha256 = "0kp9nap64287g3cj0w1lxpgyvlbqkins8bwpwafixmb29l0xyixl";
      subPackages = ["cmd/"];
      };
  
    kubectl-topology =  buildGoModule rec {
      pname = "kubectl-topology";
      version = sources.kubectl-topology.version;
      src = fetchFromGitHub {
        owner = sources.kubectl-topology.owner;
        repo = sources.kubectl-topology.repo;
        rev = "v${version}";
        sha256 = sources.kubectl-topology.sha256;
        };
      vendorSha256 = "18j6lv4aar1fwr9cb186j0mb0kirvhx8m2k98fjqpx50dmiqb695";
      subPackages = ["cmd/kubectl-topology"];
      };
    };

  packages=(builtins.map(x: (builtins.getAttr x plugins)) (builtins.attrNames plugins));
  kubectl-all = kubectl.overrideAttrs (old: {
    buildInputs = [ makeWrapper ];
    installPhase = old.installPhase + ''
      wrapProgram "$out/bin/kubectl" --prefix PATH ":" ${stdenv.lib.makeBinPath(packages)}
    '';
  });
}
