{ stdenv
, source
, buildGoPackage
}:

with builtins;

buildGoPackage rec {
  pname = "safe";
  version = source.version;
  src = source.outPath;

  goPackagePath = "github.com/starkandwayne/safe";

  meta = with stdenv.lib; {
    description = "A Vault CLI";
    homepage = "https://github.com/starkandwayne/safe";
    license = licenses.mit;
    maintainers = with maintainers; [ eonpatapon ];
  };
}
