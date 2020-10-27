{ sources
, pkgs
}:

{

  diff = let
    source = sources.helm-diff;
  in pkgs.buildGoModule rec {
    pname = "helm-diff";
    version = source.version;
    src = pkgs.fetchFromGitHub {
      owner = source.owner;
      repo = source.repo;
      rev = "v${version}";
      sha256 = source.sha256;
    };
    vendorSha256 = "005d0j7lhfcal31lqx40gy7fa5xqj8mfwim0j4adidbawq3d0zzs";
    postInstall = ''
      mv $out/bin/helm-diff $out/bin/diff
    '';
  };

}
