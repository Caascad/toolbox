# List of derivations to push in toolbox binary cache
let
  tb = import ./default.nix {};
in with tb; {
  inherit terraform safe fly tf kswitch toolbox openstackclient;
}
