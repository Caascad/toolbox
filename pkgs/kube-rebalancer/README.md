# kube-rebalancer

## Build

From toolbox repo root:

```sh
nix-build -A kube-rebalancer
```

## Dev

Hack in `./src`, then from the provided nix-shell you can run
`./src/bin/rebalancer-move-pods`.

```sh
$ pwd
/path/to/toolbox/pkgs/kube-rebalancer
$ nix-shell
$ ./src/bin/rebalancer-move-pods
...
```
