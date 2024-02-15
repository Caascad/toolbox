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

  ketall = buildGoModule rec {
    pname = "kubectl-ketall";
    version = sources.ketall.version;
    src = fetchFromGitHub {
      owner = sources.ketall.owner;
      repo = sources.ketall.repo;
      rev = "v${version}";
      sha256 = sources.ketall.sha256;
    };
    # vendorHash = lib.fakeHash;
    vendorHash = "sha256-lxfWJ7t/IVhIfvDUIESakkL8idh+Q/wl8B1+vTpb5a4=";
    postInstall = ''
      mv $out/bin/ketall $out/bin/kubectl-ketall
    '';
  };

} // pkgs.lib.optionalAttrs (! pkgs.stdenv.isDarwin) rec {
  sniff = buildGoModule rec {
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
    # vendorHash = lib.fakeHash;
    vendorHash = "sha256-7pSpOF8UASWqRMWaomoUBA3pD8t0qWiaIcGlXEm0Yx0=";
    subPackages = ["cmd/"];
  };

  tail = buildGoModule rec {
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
    # vendorHash= lib.fakeHash;
    vendorHash= "sha256-u6/LsLphaqYswJkAuqgrgknnm+7MnaeH+kf9BPcdtrc=;
    subPackages = ["cmd/kail/"];
  };

  topology = buildGoModule rec {
    pname = "kubectl-topology";
    version = sources.kubectl-topology.version;
    src = fetchFromGitHub {
      owner = sources.kubectl-topology.owner;
      repo = sources.kubectl-topology.repo;
      rev = "v${version}";
      sha256 = sources.kubectl-topology.sha256;
    };
    # vendorHash = lib.fakeHash;
    vendorHash = "sha256-JZmFY22g9IulQ2mKijrcOU6wKpAGhcVS5i5kpcimRqI"; 
    subPackages = ["cmd/kubectl-topology"];
  };
}
