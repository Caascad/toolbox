{ sources ? import ../nix/sources.nix
, nixpkgs ? sources.nixpkgs
}:

with import nixpkgs {};

runCommand "toolbox-deps" {
  buildInputs = [ git coreutils utillinux ];
} ""
