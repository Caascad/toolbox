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

#### Install on MacOS Catalina

`/` is no more writable therefore `/nix/store` cannot be created by the
`nix` install script. You can follow one of the solutions described
[here](https://github.com/NixOS/nix/issues/2925#issuecomment-604501661).

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
specific commit of the toolbox (eg: `origin/master` commit `sha` at the time you run
the command). A `toolbox.json` that references the commit used is also created.

You need to commit `shell.nix` and `toolbox.json` in the project.

#### Activating the shell

You can do it with two methods:

1. `direnv`: in `.envrc` add `use_nix`

   When you cd in the project `direnv` will automagically make the tools
   available in your shell by overriding `$PATH`

1. run `nix-shell` to start a new `bash` with the project tools defined in
   `$PATH`. You can exit the shell by typing `exit`.

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
### Updating
We manage sources within 2 files:
* nix/sources.json: handled by niv
* providers.json: terraform providers handled by [update-provider](./update-provider) and [update-all-providers](./update-all-providers)

Quickly, a full toolbox update should be performed this way:

```code
niv update nixpkgs # update nixpkgs
nix-shell --command ./autoupdate/update.py # update all sources managed by niv with autoupdate set to true
( 
    cd autoupdate
    ./update-all-providers # update all terraform providers which are not in nixpkgs
)
```

Checking:

```code
nix-build
nix-build -A terraform-providers
```

Pushing to cachix:

```code
nix-build | cachix push toolbox
nix-build -A terraform-providers | cachix push toolbox
```

#### Managing sources with autoupdate
We have a small helper to autoupdate entries in nix/sources.json without the attribute autoupdate set to false.
The helper will try to build everything and in case a vendorSha256 is outputed will add it to nix/sources.json.

niv ignore this attribute and won't try to delete it unless you drop the source (niv drop ...).

```code
./autoupdate/update.py
```

Entries with autoupdate attribute set to true should be treated manually with niv if relevant (ie we did not delibarately pinned the package version).

#### Managing sources with niv

Sources of `nixpkgs` or custom packages are managed with [niv](https://github.com/nmattia/niv). You can install it this way:
```sh
nix-env -iA nixpkgs.niv
```

To add sources of a github repo:

```sh
niv add concourse/concourse -v 7.6.0 -t 'https://github.com/<owner>/<repo>/archive/v<version>.tar.gz'
```

Once added you can use `sources.concourse` as an input of your package.
See `./pkgs/vault-token-helper.nix` for example.

To update sources to a particular version:

```sh
niv update concourse -v 7.6.0
```

[!NOTE]
nixpkgs must be updated with niv. In providers.json its autoupdate attribute is set to false:

```code
niv update nixpkgs
```

#### golang sources
Currently nixpkgs moves to hash and vendorHash attributes populated with SRI hashes values.
Currenty niv does not support vendorHash attribute so we need to add it directly in buildGo.* helpers.

```
buildGoModule rec {
    ...
    vendorSha = lib.fakeSha; # will help you get the new sri hash
    # vendorSha = "sha256-......" # to uncomment when the new sri hash is known
    }
```


Moreover a golang project from the old style building (packages) to the new one (modules). In golang modules, the vendor directory can be there or not. nix can trust it if asked. This situation creates a lot of case and situations where updating toolbox will break golang builds.

The [autoupdate script](./autoupdate/update.py) takes care to add vendorSha256

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

### Unfree packages
Because Hashicorp Vault went unfree, it is considered as impure by nix.
The toolbox script has been updated to refect it, but to be able to issue nix-.\* commands directly into the toolbox repo, you will need to export a variable:

```bash
export NIXPKGS_ALLOW_UNFREE=1
```
In the current repo you will find an envrc.EXAMPLE file to source.

### Managing terraform providers sources
#### Automated management

Adding a new provider or update an existing one. Its code must be located on Github:

```code
./update-provider <owner>/<repo>
```

Example:

```code
./update-provider terraform-provider-concourse/concourse
```

If the build fails because of vendor dir try to set vendorHash to null in providers.json then re-build:

```code
./update-provider terraform-provider-concourse/concourse --force
```

#### Detailed management

We manage few providers with the same mechanism used in nixpkgs. Our custom providers are managed through [a json file](./providers.json)

A provider is defined by this block:
```code
  "harbor": {
    "hash": "sha256-fxr5iiVxSHbDzpzyEo0ZPq9/Kc4K799uScDEUrhbLdQ=",
    "homepage": "https://registry.terraform.io/providers/goharbor/harbor",
    "owner": "goharbor",
    "repo": "terraform-provider-harbor",
    "rev": "v3.10.8",
    "spdx": "MIT",
    "vendorHash": "sha256-eFPvBl+j9QciFfPfpfwdJNb1r+DoaGldpx17saNZWqE="
   },
```

Here we define a provider named harbor located on github (github is implied) and published through the terraform registry. The revision and licenses are also needed.
The *hash* attribute is given by:

```code
nix-prefetch-url  --unpack https://github.com/${owner}/${repo}/archive/${rev}.tar.gz
```

It can also be obtained by filling the attribute with a fake hash: "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

So with this provider block:

```code
  "harbor": {
    "hash": "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    "homepage": "https://registry.terraform.io/providers/goharbor/harbor",
    "owner": "goharbor",
    "repo": "terraform-provider-harbor",
    "rev": "v3.10.8",
    "spdx": "MIT",
    "vendorHash": "sha256-eFPvBl+j9QciFfPfpfwdJNb1r+DoaGldpx17saNZWqE="
   },
```

A build will give the correct hash output:
```code
 nix-build -A terraform-providers.harbor
 ...
error: hash mismatch in fixed-output derivation '/nix/store/vq6l9klwbryiacrk3fif3qb4zi14gav0-source-v3.10.8.drv':
         specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
            got:    sha256-fxr5iiVxSHbDzpzyEo0ZPq9/Kc4K799uScDEUrhbLdQ=
error: 1 dependencies of derivation '/nix/store/mlmdix3rlin4s9r3534b6x201hcbz9ax-terraform-provider-harbor-3.10.8.drv' failed to build
```

The same method apply to *vendorHash* attribute

[!IMPORTANT]
*About golang builds*: there is several ways to compile a golang project depending on the golang version, vendoring, etc..
Most of those variants can be reached through a trick  on vendorHash and overrides defined in default.nix (see the harbor example which forces golang 1.22).
When vendorHash is set and is not empty, nix will issue go mod commands, downloading dependencies. If vendorHash is null, nix will configure golang to use the vendor directory.

[!NOTE]
The providers.json file can also be obtained by a script in nixpkgs:

```bash
## In the toolbox repo
REV=$(jq -r '."nixpkgs-unstable".rev' nix/sources.json)
## In nixpkgs repo
cd pkgs/applications/networking/cluster/terraform-providers/
git checkout "${REV}"
./update-provider terraform-provider-concourse/concourse
./update-provider caascad/privx
./update-provider idealo/controltower # vendorHash needs to be set to null after
./update-provider goharbor/harbor
```

### Pushing to cachix

```bash
toolbox install pkgs.cachix
export CACHIX_SIGNING_KEY=<toolbox signing key>
nix-build | cachix push toolbox
nix-build -A terraform-providers | cachix push toolbox
```

### Terraform provider source address
Previously we overrided the provider source address of every terraform provider we would want to see in the toolbox.
Currently we do not use this mechanism anymore, so when you will update your terraform provider you may encounter such messages:
```bash
terraform init
│ Error: Failed to query available provider packages
│
│ Could not retrieve the list of available versions for provider toolbox/vault: provider registry.terraform.io/toolbox/vault was not found in any of the search locations
│
│   - /nix/store/hxpgcq849g6299mg4mv989xmjz6ypq3p-terraform-1.7.1/libexec/terraform-providers
╵

tree /nix/store/hxpgcq849g6299mg4mv989xmjz6ypq3p-terraform-1.7.1/libexec/terraform-providers
/nix/store/hxpgcq849g6299mg4mv989xmjz6ypq3p-terraform-1.7.1/libexec/terraform-providers
└── registry.terraform.io
    ├── hashicorp
    │   ├── vault
    │   │   └── ...
    │   │
    │   │


```
The provider has been moved to a new location due to provider source address attribute change.

To fix the state:
```bash
terraform state replace-provider registry.terraform.io/toolbox/vault registry.terraform.io/hashicorp/vault
```

Also ensure every terraform block in terraform configurations reflects the new provider source address:
```bash
 terraform {
   required_providers {
     vault = {
-      source                = "toolbox/vault"
+      source                = "hashicorp/vault"
       configuration_aliases = [vault.src, vault.dest]
     }
   }
```

Remember those blocks can be set in configurations and modules also.
