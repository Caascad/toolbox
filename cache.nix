# List of derivations to push in toolbox binary cache
let
  toolbox = import ./default.nix {};
in with toolbox; {
  inherit terraform safe fly tf kswitch;
}
