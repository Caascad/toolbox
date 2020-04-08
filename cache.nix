# List of derivations to push in toolbox binary cache
let
  sources = import ./nix/sources.nix;

  pkgs = import sources.nixpkgs {};

  tb = import ./default.nix {};

  # custom builds to push in toolbox binary cache
  cache = [
    "terraform"
    "safe"
    "fly"
    "tf"
    "kswitch"
    "toolbox"
    "openstackclient"
  ];

in

with builtins;
with pkgs.lib;

filterAttrs (n: _: elem n cache) tb
