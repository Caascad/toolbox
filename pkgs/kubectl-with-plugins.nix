{ lib
, stdenv
, makeWrapper
, plugins
, kubectl
, installShellFiles
}:

stdenv.mkDerivation {
  pname = "kubectl-with-plugins";
  version = kubectl.version;
  buildInputs = [ makeWrapper installShellFiles ];
  unpackPhase = ":";
  installPhase = ''
    mkdir -p $out/bin

    ln -s ${kubectl}/bin/kubectl $out/bin/kubectl

    wrapProgram "$out/bin/kubectl" --prefix PATH ":" ${lib.makeBinPath (builtins.attrValues plugins)}

    installShellCompletion --cmd kubectl \
      --bash <($out/bin/kubectl completion bash) \
      --zsh <($out/bin/kubectl completion zsh)
  '';
}
