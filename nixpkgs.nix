{ sources ? import ./nix/sources.nix }:

let
  toolbox = self: super: import ./default.nix {};
in import sources.nixpkgs { overlays = [ toolbox ]; }
