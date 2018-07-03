{ ... }:

with (import ../lib.nix);

let
  iohk-pkgs = import ../default.nix {};

in {
  network.description = "Testnet Deployer";

  testnet-deployer = { config, pkgs, resources, ... }: {
    imports = [
      ../modules/common.nix
      ../modules/datadog.nix
      ../modules/papertrail.nix
      ../modules/deployer-base.nix
    ];

    services.dd-agent.tags = ["env:production" "depl:${config.deployment.name}" "role:deployer"];
    networking.hostName = "testnet-deployer";

    users.groups.developers = {};

    users.users = {
      # Deploy cardano-sl testnet
      testnet = {
        isNormalUser = true;
        description  = "Cardano SL Testnet NixOps Deployer";
        group        = "deployers";
        openssh.authorizedKeys.keys = devOpsKeys;
      };

      # Deploy cardano-sl staging network
      staging = {
        description  = "Staging NixOps deployer";
        group        = "deployers";
        isNormalUser = true;
        openssh.authorizedKeys.keys = devOpsKeys;
      };

      # Deploy mantis (kevm/iele) testnet
      mantis-testnet = {
        isNormalUser = true;
        description  = "Mantis Testnet NixOps Deployer";
        group        = "deployers";
        openssh.authorizedKeys.keys = mantisOpsKeys;
      };

      # Deploy Hydra and agents
      infra = {
        description  = "CI NixOps deployer";
        group        = "deployers";
        isNormalUser = true;
        openssh.authorizedKeys.keys = devOpsKeys;
      };
    }
    # Normal users who can deploy developer clusters on AWS.
    // mapAttrs (name: keys: {
      group = "developers";
      isNormalUser = true;
      openssh.authorizedKeys.keys = keys;
    }) (csl-developers // devOps);

    deployment.keys.tarsnap = {
      keyFile = ./../static/tarsnap-testnet-deployer.secret;
      destDir = "/var/lib/keys";
    };

    services.tarsnap = {
      enable = true;
      keyfile = "/var/lib/keys/tarsnap";
      archives.testnet-deployer = {
        directories = [
          "/home"
          "/etc/"
        ];
      };
    };
  };
}
