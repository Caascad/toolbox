# How to create poetry files
Just start nix-shell
The shell will load poetry2nix from stable nixpkgs. Later versions seems broken.
Start the nix-shell to build dependencies with poetry
```sh
nix-shell
```
## Notes for 6.2 upgrade
Poetry tries to update cryptography to v41, but the version of nixpkgs we use does not reference this version in its poetry.lock, so we had to pin the version:
```console
poetry add cryptography@40.0.2
```
Poetry seems to miss some dependencies
```console
poetry add maturin
poetry add setuptools
poetry add setuptools-rust
```
and in poetry.lock add maturin as a dependency of rpds-py, then add setuptools and setuptools-rust as dependencies of maturin.

