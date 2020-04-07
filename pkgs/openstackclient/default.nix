{ pkgs }:

let p = import ./requirements.nix { inherit pkgs; };
in p.packages.openstackclient
