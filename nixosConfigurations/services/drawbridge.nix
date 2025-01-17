{
  self,
  flake-utils,
  ...
}:
with flake-utils.lib.system; let
  mkDrawbridge = self.lib.hosts.mkService [
    ({
      config,
      pkgs,
      ...
    }: {
      services.drawbridge.enable = true;
      services.drawbridge.tls.caFile = pkgs.writeText "ca.crt" (builtins.readFile "${self}/ca/${config.networking.domain}/ca.crt");

      services.nginx.clientMaxBodySize = "100m";
    })
  ];

  store-testing = mkDrawbridge x86_64-linux [
    ({pkgs, ...}: {
      imports = [
        "${self}/hosts/store.testing.profian.com"
      ];

      services.drawbridge.log.level = "debug";
      services.drawbridge.oidc.client = "zFrR7MKMakS4OpEflR0kNw3ceoP7sr3s";
      services.drawbridge.package = pkgs.drawbridge.testing;
    })
  ];

  store-staging = mkDrawbridge x86_64-linux [
    ({pkgs, ...}: {
      imports = [
        "${self}/hosts/store.staging.profian.com"
      ];

      services.drawbridge.log.level = "info";
      services.drawbridge.oidc.client = "9SVWiB3sQQdzKqpZmMNvsb9rzd8Ha21F";
      services.drawbridge.package = pkgs.drawbridge.staging;
    })
  ];

  store = mkDrawbridge x86_64-linux [
    ({pkgs, ...}: {
      imports = [
        "${self}/hosts/store.profian.com"
      ];

      services.drawbridge.oidc.client = "2vq9XnQgcGZ9JCxsGERuGURYIld3mcIh";
      services.drawbridge.package = pkgs.drawbridge.production;
    })
  ];
in {
  inherit
    store
    store-staging
    store-testing
    ;
}
