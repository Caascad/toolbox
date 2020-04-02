# Caascad toolbox

This project contains tools for working with Caascad projects.

Goals are:

  * just works
  * compatible with any Linux distribution or MacOS
  * central place for getting tools required to work on a project
  * easy new comer onboarding
  * avoid version mismatch between people and the CI

## Getting started

### Installation

To install the toolbox run:

```
curl https://raw.githubusercontent.com/Caascad/toolbox/master/install | sh
```

This will install and configure `nix` and the `toolbox` on your system.

Don't forget to configure your `.bashrc`.

### Listing tools

To view the list of available tools run:

```bash
$ toolbox list
ansible          2.8.4 - ?       Radically simple IT automation
cfssl            1.3.2 = 1.3.2   Cloudflare's PKI and TLS toolkit
helm             3.0.1 > 2.14.3  A package manager for kubernetes
...
```

We can see that:

 * ansible `2.8.4` is available but not installed (`?`)
 * cfssl is globally installed at the latest version (`1.3.2`)
 * helm `3.0.1` in available but `2.14.3` is globally installed (`>`)

_This only show installed versions from the toolbox, not the packages
you might have installed with your distribution._

### Create a development shell for a project

A development shell provides a list of tools to work with a project.
This development shell guarantees that the tools are pinned to a specific
"version" for the project. And so that anyone that works with the project
uses the same exact tools.

In other words you don't care if tools are updated at some point in the
toolbox, you always get the same tools at the same version in your project.
You are sure that everyone working in the project has the same exact tools.

As a maintainer of the project you control when to update the versions of
the tools for your project.

This means you don't need to install the tools globally.

#### Shell setup

Given a project X which needs the tools `terraform` and `ansible` go to the
root directory of the project and run:

```sh
toolbox make-shell terraform ansible
```

This will create a `shell.nix` file that list the tools of the project.
In this example `terraform` and `ansible`. Theses tools are pinned to a
specific commit of the toolbox (eg: `origin/master` commit at the time you run
the command). A `toolbox.json` that references the commit used is also created.

You need to commit `shell.nix` and `toolbox.json` in the project.

#### Activating the shell

You can do it with two methods:

1. `direnv`: in `.envrc` add `use_nix`

   When you cd in the project `direnv` will automagically make the tools
   available in your shell.

1. run `nix-shell` to enter a new shell with the project tools

#### Shell update

After some time you decide to use a newer version of `terraform` or
`ansible` which are available in the toolbox.

To update the shell to the latest toolbox version, run:

```sh
toolbox update-shell
```

This will update `toolbox.json` with the last commit of the master branch.

You can also update the shell using a specific commit:

```sh
toolbox update-shell <commit-sha>
```

Test that the new versions of the tools play well with your project. If yes,
you can commit `toolbox.json`.

### Globally installing a tool

**If your goal is to use a tool for working on a project you want to setup a
development shell described in the previous section.**

Run the following to install `terraform`:

```bash
$ toolbox install terraform
[toolbox]: Running "nix-env -f default.nix -iA terraform"

installing 'terraform-with-plugins-0.12.8'

$ terra<TAB>
```

`terraform` command should be available globally in your shell.

### Globally uninstall a tool

Run the following to uninstall `terraform`:

```bash
$ toolbox uninstall terraform
[toolbox]: Running "nix-env -e terraform-with-plugins-0.12.8"

uninstalling 'terraform-with-plugins-0.12.8'
```

`terraform` command is no longer available from your shell.

### Globally update tools

Run:

```sh
$ toolbox update
```

This will update the git repository and update any already globally
installed tools if a superior version is available.

## Advanced

### Bash completions

You can get bash completions for `toolbox`. Just setup the following
in your `.bashrc`:

```bash
source <(toolbox completions)
```

### Add tools required by your project in the toolbox

Suppose a tool you need in your project is not available yet in the
toolbox.

In order to iterate locally, you can generate a `shell.nix` file and
manually replace the `src` attribute by `src = /your/toolbox/location`
in order to point to your local toolbox repository. You can then add
tools in the toolbox and test this nix-shell before creating a pull
request in the toolbox repository.

## Submitting changes

Follow `nixpkgs` format of git commits:

```
(pkg-name): (from -> to | init at version | refactor | etc)

(Motivation for change. Additional information.)
```

For consistency, there should not be a period at the end of the commit
message's summary line (the first line of the commit message).

Examples:

* `terraform: init at 0.12.0`
* `cue: 0.0.14 -> 0.0.15`

## Maintainers

### Managing sources

Sources of `nixpkgs` or custom packages are managed with [niv](https://github.com/nmattia/niv). You can install it this way:
```sh
nix-env -iA nixpkgs.niv
```

To add sources of a github repo:

```sh
niv add concourse/concourse -v 5.8.0 -t 'https://github.com/<owner>/<repo>/archive/<version>.tar.gz'
```

Once added you can use `sources.concourse` as an input of your package.
See `./pkgs/safe.nix` for example.

To update sources to a particular version:

```sh
niv update concourse -v 5.8.1
```

### Testing a new package locally

After adding a new package in the toolbox you can build it with:

```sh
nix-build -A <name>
```

If you want to install it in your profile run:

```sh
nix-env -f default.nix -iA <name>
```

To test `toolbox` with local packages run:

```sh
NIX_PATH=toolbox=/path/to/toolbox/repo toolbox list
```
