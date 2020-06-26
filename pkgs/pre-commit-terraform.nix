{ stdenv
, makeWrapper
, pythonPackages
, terraform
, terraform-docs
, tflint
, shellcheck
}:

stdenv.mkDerivation {
  pname = "pre-commit-terraform";
  version = pythonPackages.pre-commit.version;

  phases = [ "installPhase" ];

  buildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    ln -s ${pythonPackages.pre-commit}/bin/pre-commit $out/bin
    wrapProgram $out/bin/pre-commit --prefix PATH ":" "${terraform}/bin:${terraform-docs}/bin:${tflint}/bin:${shellcheck}/bin"
  '';

  meta = with stdenv.lib; {
    description = "Wrapper around pre-commit to test terraform code";
    homepage = "https://pre-commit.com";
    license = licenses.mit;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
