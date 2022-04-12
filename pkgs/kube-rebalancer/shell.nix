let

  toolbox = import ../../default.nix {};

  pkgs = toolbox.pkgs;

in pkgs.mkShell {
  buildInputs = with pkgs; [
    (python39.withPackages (ps: toolbox.kube-rebalancer.propagatedBuildInputs))
  ];
  shellHook = ''
    export PYTHONPATH="$PYTHONPATH:$(pwd)/src"
    '';
}
