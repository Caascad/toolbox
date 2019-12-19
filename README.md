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

    $ ./toolbox init
    [toolbox]: Initializing setup ...
    [toolbox]: Looks like nix is not installed yet
    [toolbox]: Running 'curl https://nixos.org/nix/install | sh'

    ...

    Installation finished!  To ensure that the necessary environment
    variables are set, please add the line

      . /home/user/.nix-profile/etc/profile.d/nix.sh

    to your shell profile (e.g. ~/.profile).

This will install and configure `nix` on your system.

Don't forget to source the `nix.sh` profile in your `.profile` or `.bash_rc`.

### Listing tools

To view the list of available tools run:

    $ ./toolbox list
    ansible    = 2.8.4  Radically simple IT automation
    helm       - ?      A package manager for kubernetes
    kubectl    - ?      Kubernetes CLI
    stern      - ?      Multi pod and container log tailing for Kubernetes
    terraform  - ?

We can see that `ansible` v2.8.4 is installed and it is the latest version available (`=`).

Other tools are not installed (`?`).

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

### Update tools

Run:

    $ ./toolbox update

This will update the git repository and update any already installed
tool if a superior version is available.

## Advanced setup

### Bash completions

You can get bash completions for `toolbox`. Just setup the following
in your `.bashrc`:

    alias toolbox=/path/to/toolbox
    source <(/path/to/toolbox completions)
