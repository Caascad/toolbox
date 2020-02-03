{ sources ? import ../nix/sources.nix
, nixpkgs ? sources.nixpkgs
}:

with import nixpkgs {};

# List of depedencies used to run toolbox subcommands
runCommand "toolbox-deps" {
  buildInputs = [
    bashInteractive
    bashInteractive.man
    bashInteractive.info
    bashInteractive.doc
    coreutils
    utillinux
  ];
} "touch $out"
