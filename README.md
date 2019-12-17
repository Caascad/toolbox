# Caascad toolbox

This project contains tools for working with Caascad projects.

Goals are:

  * just works
  * compatible with any Linux distribution or MacOS
  * central place for getting a tool required to work on a project
  * easy new comer onboarding
  * avoid version mismatch between people and the CI

## Getting started

### Setup

To setup the toolbox and start using tools run the following command:

    ./toolbox init

This will install and configure `nix` on your system.

### Listing tools

To view the list of available tools run:

    ./toolbox list

### Installing a tool

Run the following to install `terraform`:

    $ ./toolbox install terraform
    [toolbox]: Running "nix-env -f default.nix -iA terraform"

    installing 'terraform-with-plugins-0.12.8'

    $ terra<TAB>

`terraform` command should be available in your shell.

### Uninstall a tool

Run the following to uninstall `terraform`:

    $ ./toolbox uninstall terraform
    [toolbox]: Running "nix-env -e terraform-with-plugins-0.12.8"

    uninstalling 'terraform-with-plugins-0.12.8'

`terraform` command is no longer available from your shell.

## Advanced setup

### Make `toolbox` available globally

Just link `./toolbox` to some dir that is in your `$PATH`.

### Bash completions

You can get bash completions for `./toolbox`. Just setup the following
in your `.bashrc`:

    source <(./toolbox completions)
