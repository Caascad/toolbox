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

  vendorSha256 = "0rpz8syingvj9s1wwhsdmhl2pcbwvj0zirgvgnp6653arwwlpqc8";

  meta = with lib; {
    description = "Vault Token Helper with support for native credential storage";
    homepage = "https://github.com/joemiller/vault-token-helper";
    license = licenses.mit;
    maintainers = with maintainers; [ ivanbrennan ];
  };

}
