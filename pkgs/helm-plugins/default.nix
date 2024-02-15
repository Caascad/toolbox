{ sources
, pkgs
, fetchpatch
, lib
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
    # vendorHash = lib.fakeHash;
    vendorHash = "sha256-51xjHGU9TC4Nwa9keR0b7bgwpZcRmG7duT9R1JRr3Uw";
    postInstall = ''
      mv $out/bin/helm-diff $out/bin/diff
    '';
  };

}
