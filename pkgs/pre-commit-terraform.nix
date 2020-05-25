{ stdenv
, makeWrapper
, pythonPackages
, terraform
, terraform-docs
, tflint
, shellcheck
}:

let

  pre-commit = pythonPackages.pre-commit.overrideAttrs(old: {
    # Patch pre_commit to use builtin virtualenv module of python (venv) instead
    # of thirdparty virtulenv module because of some incompability with nix:
    # https://github.com/NixOS/nixpkgs/issues/66366
    postInstall = ''
      sed -i 's/cmd =.*/cmd = (sys.executable, "-mvenv", envdir)/'\
        $out/${pythonPackages.python.sitePackages}/pre_commit/languages/python.py
    '';
  });

in stdenv.mkDerivation {
  pname = "pre-commit-terraform";
  version = pythonPackages.pre-commit.version;

  phases = [ "installPhase" ];

  buildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    ln -s ${pre-commit}/bin/pre-commit $out/bin
    wrapProgram $out/bin/pre-commit --prefix PATH ":" "${terraform}/bin:${terraform-docs}/bin:${tflint}/bin:${shellcheck}/bin"
  '';

  meta = with stdenv.lib; {
    description = "Wrapper around pre-commit to test terraform code";
    homepage = "https://pre-commit.com";
    license = licenses.mit;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
