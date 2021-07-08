{saml2aws
,fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "saml2aws";
  version = "2.28.0";
   src = fetchFromGitHub {
    owner = "Versent";
    repo = "saml2aws";
    rev = "v${version}";
    sha256 = "04gg3kzh52wr3crypn4p3yikxmv7223k3cn5araih0z3sb54rpfs";
  };

  runVend = true;
  vendorSha256 = "06if5aciv7jqb3r67mfkchmky5szipvirqwy2vzinnmjb39k3aph";

  doCheck = false;
}
