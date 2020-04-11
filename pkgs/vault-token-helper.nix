{ buildGoModule, source, lib }:

buildGoModule rec {
  pname = "vault-token-helper";
  version = source.version;
  src = source.outPath;

  modSha256 = "174wr2xvwjiix5c29w2wlgi36hv02fcwhdmhqdn8q6pxs4ahy65m";

  meta = with lib; {
    description = "Vault Token Helper with support for native credential storage";
    homepage = "https://github.com/joemiller/vault-token-helper";
    license = licenses.mit;
    maintainers = with maintainers; [ ivanbrennan ];
  };

}
