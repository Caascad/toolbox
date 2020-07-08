{ buildGoPackage, fetchFromGitHub }:
buildGoPackage rec {
  name = "krew-${version}";
  version = "0.3.4";
  goPackagePath = "sigs.k8s.io/krew";
  src = fetchFromGitHub {
    owner = "kubernetes-sigs";
    repo = "krew";
    rev = "v${version}";
    sha256 = "0n10kpr2v9jzkz4lxrf1vf9x5zql73r5q1f1llwvjw6mb3xyn6ij";
  };
  goDeps = ./deps.nix;
}
