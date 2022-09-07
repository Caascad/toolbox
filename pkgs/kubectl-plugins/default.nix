{ sources
, pkgs
}:

with pkgs;
rec {
  node-shell = callPackage ./scripts.nix {
    source = sources.kubectl-node-shell;
    cmdName = "kubectl-node_shell";
    scriptPatches = [./kubectl-node-shell-toleration.patch];
  };

  spy = callPackage ./scripts.nix {
    source = sources.kubespy;
    cmdName = "kubespy";
    outCmdName = "kubectl-spy";
  };

  ctx = kubectx.overrideAttrs (old: {
    installPhase = old.installPhase + ''
      mv $out/bin/kubectx $out/bin/kubectl-ctx
      mv $out/bin/kubens  $out/bin/kubectl-ns
    '';
  });

  tail = buildGo117Module rec {
    pname = "kubectl-tail";
    version = sources.kail.version;
    postInstall = ''
      mv $out/bin/kail $out/bin/kubectl-tail
    '';
    src = fetchFromGitHub {
      owner = sources.kail.owner;
      repo = sources.kail.repo;
      rev = "v${version}";
      sha256 = sources.kail.sha256;
    };
    vendorSha256 = sources.kail.vendorSha256;
    subPackages = ["cmd/kail/"];
  };

  sniff = buildGo117Module rec {
    pname = "kubectl-sniff";
    version = sources.ksniff.version;
    postInstall = ''
      mv $out/bin/cmd $out/bin/kubectl-sniff
    '';
    src = fetchFromGitHub {
      owner = sources.ksniff.owner;
      repo = sources.ksniff.repo;
      rev = "v${version}";
      sha256 = sources.ksniff.sha256;
    };
    vendorSha256 = sources.ksniff.vendorSha256;
    subPackages = ["cmd/"];
  };

  topology = buildGo117Module rec {
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

  ketall = buildGoModule rec {
    pname = "kubectl-ketall";
    version = sources.ketall.version;
    src = fetchFromGitHub {
      owner = sources.ketall.owner;
      repo = sources.ketall.repo;
      rev = "v${version}";
      sha256 = sources.ketall.sha256;
    };
    vendorSha256 = "1bp5bcxbszhxy0jzqhvyv24zqhljk9221m7hgr45h8bzpckxc5wp";
    postInstall = ''
      mv $out/bin/ketall $out/bin/kubectl-ketall
    '';
  };

}
