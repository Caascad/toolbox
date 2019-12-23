{ stdenv
, source
, buildGoPackage
}:

with builtins;

buildGoPackage rec {
  name = "safe-${version}";
  version = concatStringsSep "." (tail (splitVersion source.rev));
  src = source.outPath;

  goPackagePath = "github.com/starkandwayne/safe";

  meta = with stdenv.lib; {
    description = "A Vault CLI";
    homepage = "https://github.com/starkandwayne/safe";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
