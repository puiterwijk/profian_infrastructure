{
  self,
  enarx,
  flake-utils,
  nixpkgs,
  ...
}:
with flake-utils.lib.system; let
  beneficeModules.common = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; {
      imports = [
        self.nixosModules.service
      ];

      config = mkMerge [
        {
          services.benefice.enable = true;
          services.benefice.oidc.issuer = "https://auth.profian.com";
        }
        (mkIf (config.profian.environment == "testing") {
          services.benefice.log.level = "debug";
          services.benefice.package = pkgs.benefice.testing;
        })
        (mkIf (config.profian.environment == "staging") {
          services.benefice.log.level = "info";
          services.benefice.package = pkgs.benefice.staging;
        })
        (mkIf (config.profian.environment == "production") {
          services.benefice.log.level = "info";
          services.benefice.package = pkgs.benefice.production;
        })
      ];
    };

  beneficeModules.ec2 = {modulesPath, ...}: {
    imports = [
      "${modulesPath}/virtualisation/amazon-image.nix"
    ];

    networking.hostName = "benefice";

    # NOTE: /dev/kvm is not present on systems
    services.enarx.backend = "nil";

    services.steward.nginx.enable = true;
  };

  beneficeModules.equinix = {...}: {
    profian.provider = "equinix";
  };

  mkEC2 = modules:
    nixpkgs.lib.nixosSystem {
      system = x86_64-linux;
      modules =
        [
          beneficeModules.common
          beneficeModules.ec2
        ]
        ++ modules;
    };

  benefice-testing = mkEC2 [
    ({...}: {
      networking.domain = "testing.profian.com";

      profian.environment = "testing";

      services.benefice.oidc.client = "FTmeUMamlu8HRs11mvtmmZHnmCwRIo8E";
      services.benefice.demoFqdn = "benefice.testing.profian.cloud";
    })
  ];

  mkEquinix = modules:
    nixpkgs.lib.nixosSystem {
      system = x86_64-linux;
      modules =
        [
          beneficeModules.common
          beneficeModules.equinix
        ]
        ++ modules;
    };

  sgx-equinix-try = mkEquinix [
    self.nixosModules.sgx
    ({
      config,
      lib,
      ...
    }: {
      imports = [
        "${self}/hosts/sgx.equinix.try.enarx.dev"
      ];

      networking.domain = "equinix.try.enarx.dev";
      networking.hostName = "sgx";

      profian.environment = "production";

      services.benefice.oidc.client = "23Lt09AjF8HpUeCCwlfhuV34e2dKD1MH";
      services.benefice.demoFqdn = "sgx.try.enarx.profian.cloud";
    })
  ];

  snp-equinix-try = mkEquinix [
    self.nixosModules.sev
    ({...}: {
      imports = [
        "${self}/hosts/snp.equinix.try.enarx.dev"
      ];

      networking.domain = "equinix.try.enarx.dev";
      networking.hostName = "snp";

      profian.environment = "production";

      services.benefice.oidc.client = "Ayrct2YbMF6OHFN8bzpv3XemWI3ca5Hk";
      services.benefice.demoFqdn = "snp.try.enarx.profian.cloud";
    })
  ];
in {
  inherit
    benefice-testing
    sgx-equinix-try
    snp-equinix-try
    ;
}
