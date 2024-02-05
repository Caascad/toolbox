{ buildGoModule
, fetchzip
, source
, lib
}:

buildGoModule rec {
  pname = "vault-token-helper";
  version = source.version;
  src = fetchzip {
    inherit (source) url sha256;
  };
  # vendorHash= lib.fakeHash;
  vendorHash = "sha256-b/ufutR2JUgmPQBgif24ipAh7TWaqxo+sGCDv4BvdHU=";

  doCheck = false;

  meta = with lib; {
    description = "Vault Token Helper with support for native credential storage";
    homepage = "https://github.com/joemiller/vault-token-helper";
    license = licenses.mit;
    maintainers = with maintainers; [ ivanbrennan ];
  };

}
