with builtins;

{

  list = concatStringsSep "\n" (
    attrValues (mapAttrs (a: d: "${a} ${(parseDrvName d.name).version}") (import ./default.nix {}))
  );

}
