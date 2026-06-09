{
  config,
  username,
  hostname,
  pkgs,
  lib,
  nix-index-database,
  inputs,
  specialArgs,
  ...
}: let
  ddnsPkg = import ./invoke-ddns {inherit pkgs;};

  startSeq = builtins.fromJSON ''"[7m"'';
  endSeq = builtins.fromJSON ''"[27m"'';
  motd = "${startSeq} Welcome to Bob's Server! ${endSeq}";

  nixPkgs = specialArgs.nixPkgs;
  ourRustVersion = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.complete);

  ourRustPlatform = nixPkgs.makeRustPlatform {
    rustc = ourRustVersion;
    cargo = ourRustVersion;
  };

  pullomaticPkg = import ./pullomatic {
    inherit lib pkgs;
    rustPlatform = ourRustPlatform;
    specialArgs = {};
  };

  pullomatic = "${pullomaticPkg}/bin/pullomatic";
in {
  imports = [
    (import ./cloned_repos {inherit pkgs pullomatic lib;})
    (import ./firewall.nix {inherit pkgs;})
    (import ./nginx.nix {inherit pkgs lib config;})
    (import ./system/users.nix {inherit pkgs config lib nix-index-database;})
  ];

  # FIXME: set your timezone
  time.timeZone = "America/Chicago";

  age.secrets = {
    nearlyfreespeech = {
      file = ./secrets/nearlyfreespeech.age;
      owner = "root";
    };

    webdav = {
      file = ./secrets/webdav.age;
      owner = "root";
    };

    # Optional: only needed if you use claude-code or other Anthropic tools
    anthropic-api-key = {
      file = ./secrets/anthropic-api-key.age;
      owner = "root";
    };

    forgejo-runner-token = {
      file = ./secrets/forgejo-runner-token.age;
      owner = "root";
    };

    paperless = {
      file = ./secrets/paperless.age;
      owner = "root";
    };
  };

  environment.systemPackages = [
    ddnsPkg
    pullomaticPkg
    pkgs.vim
    pkgs.php
    pkgs.rustc
    pkgs.cargo
    pkgs.util-linux
    pkgs.iotop
    pkgs.rust-bin.stable.latest.default
    pkgs.wget
    pkgs.tmux

    # Uncomment to install Claude Code on the server:
    # pkgs.unstable.claude-code
  ];

  swapDevices = [
    {
      device = "/swapfile";
      size = 1 * 1024; # 1GB
    }
  ];

  virtualisation.arion = {
    backend = "podman-socket";
    projects.forgejo.settings = import ./arion/arion-compose.nix;
    projects.riverside.settings = import ./arion-riverside/arion-compose.nix;
    projects.pluto.settings = import ./arion-pluto/arion-compose.nix;
    projects.paperless.settings = import ./arion-paperless/arion-compose.nix;
  };

  # The arion NixOS module sets backend = "podman-socket" but doesn't inject
  # DOCKER_HOST into the service units; docker CLI falls back to /var/run/docker.sock
  # (no daemon). Point it at the podman-compatible socket instead.
  systemd.services.arion-forgejo.environment.DOCKER_HOST = "unix:///run/podman/podman.sock";
  systemd.services.arion-riverside.environment.DOCKER_HOST = "unix:///run/podman/podman.sock";
  systemd.services.arion-pluto.environment.DOCKER_HOST = "unix:///run/podman/podman.sock";
  systemd.services.arion-paperless.environment.DOCKER_HOST = "unix:///run/podman/podman.sock";

  services.gitea-actions-runner.instances."ubuntu" = {
    enable = true;
    name = "ubuntu";
    # FIXME: point at your Forgejo instance
    url = "http://localhost:3000";
    tokenFile = config.age.secrets.forgejo-runner-token.path;
    labels = [
      "ubuntu-latest:host"
      "ubuntu-22.04:host"
      "ubuntu-20.04:host"
    ];
  };

  users.users.gitea-runner = {
    isSystemUser = true;
    group = "gitea-runner";
    extraGroups = ["podman"];
    home = "/var/lib/gitea-runner";
    createHome = true;
  };
  users.groups.gitea-runner = {};

  systemd.services.gitea-runner-ubuntu = {
    after = ["arion-forgejo.service"];
    wants = ["arion-forgejo.service"];
    environment.PATH = lib.mkForce (
      "${pkgs.podman}/bin:${pkgs.git}/bin:${pkgs.nodejs}/bin:/run/current-system/sw/bin:/run/wrappers/bin"
    );
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = lib.mkForce "gitea-runner";
      Group = lib.mkForce "gitea-runner";
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/ironmagma/.config 0755 ${username} users"
    "d /root/.config 0755 ${username} users"
    "d /var/pluto/notebooks 0755 root root"
    "d /var/pluto/julia-depot 0755 root root"
    "d /var/paperless/data 0755 root root"
    "d /var/paperless/media 0755 root root"
    "d /var/paperless/export 0755 root root"
    "d /var/paperless/consume 0755 root root"
    "d /var/paperless/postgres 0755 root root"
    "d /var/paperless/redis 0755 root root"
    "d /var/riverside/files 0755 root root"
    "d /var/riverside/db 0755 root root"
    "d /var/lib/gitea-runner/ubuntu 0755 gitea-runner gitea-runner"
  ];

  networking.hostName = "${hostname}";

  # FIXME: change your shell here if you don't want zsh
  programs.zsh.enable = true;
  programs.zsh.shellInit = ''
    # Uncomment if you have an anthropic-api-key secret configured:
    # export ANTHROPIC_API_KEY=$(cat ${config.age.secrets.anthropic-api-key.path})
  '';
  environment.pathsToLink = ["/share/zsh"];
  environment.shells = [pkgs.zsh];

  environment.enableAllTerminfo = true;

  security.sudo.wheelNeedsPassword = false;

  users.motd = motd;

  system.stateVersion = "22.05";

  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # KDE Plasma spawns many threads. Raise machine.slice TasksMax so podman
  # scopes don't get capped at the systemd default (~9286).
  systemd.slices.machine.sliceConfig.TasksMax = "infinity";
  virtualisation.containers.containersConf.settings.containers.pids_limit = 0;

  virtualisation.oci-containers = {
    backend = "podman";

    containers = {
      "navidrome" = {
        autoStart = true;
        environment = {
          "TZ" = "America/Chicago";
          "PUID" = "1000";
          "PGID" = "100";
          "ND_SCANSCHEDULE" = "1h";
          "ND_LOGLEVEL" = "info";
          "ND_SESSIONTIMEOUT" = "24h";
          "ND_BASEURL" = "";
        };
        ports = ["4533:4533"];
        volumes = [
          "/var/navidrome/data:/data"
          "/var/navidrome/music:/music:ro"
        ];
        image = "deluan/navidrome";
      };

      "webdav" = {
        autoStart = true;
        image = "dgraziotin/nginx-webdav-nononsense";
        volumes = [
          "/mnt/webdav/data:/data"
          "/mnt/webdav/config:/config"
        ];
        environment = {
          "WEBDAV_USERNAME" = "bob";
          "TZ" = "America/Chicago";
          "PUID" = "60"; # nginx user
          "PGID" = "60"; # nginx group
        };
        environmentFiles = [config.age.secrets.webdav.path];
        ports = ["8082:80"];
      };

      "blog-quine" = {
        autoStart = true;
        image = "quineglobal/blog-quine:latest";
        volumes = [];
        environment = {};
        ports = ["3010:8080"];
      };

      "hyper-quineglobal-com" = {
        autoStart = true;
        image = "forge.quinefoundation.com/ironmagma/hyper-quineglobal-com:latest";
        volumes = [];
        environment = {};
        ports = ["3013:8081"];
      };
    };
  };

  nix = {
    settings = {
      trusted-users = [username];
      accept-flake-config = true;
      auto-optimise-store = true;
    };

    registry = {
      nixpkgs = {
        flake = inputs.nixpkgs;
      };
    };

    nixPath = [
      "nixpkgs=${inputs.nixpkgs.outPath}"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];

    package = pkgs.nixVersions.stable;
    extraOptions = ''experimental-features = nix-command flakes'';

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  # HTTPS — DNS challenge via NearlyFreeSpeech for domains that need certs
  # before nginx is running (avoids circular systemd dependency).
  # FIXME: replace all domain names with your own.
  security.acme = {
    acceptTerms = true;
    defaults.email = "bob@bobs-home.com";

    certs."bobs-home.com" = {
      dnsProvider = "nearlyfreespeech";
      environmentFile = config.age.secrets."nearlyfreespeech".path;
      webroot = null;
    };

    certs."webdav.bobs-home.com" = {
      dnsProvider = "nearlyfreespeech";
      environmentFile = config.age.secrets."nearlyfreespeech".path;
      webroot = null;
    };

    certs."pluto.bobs-home.com" = {
      dnsProvider = "nearlyfreespeech";
      environmentFile = config.age.secrets."nearlyfreespeech".path;
      webroot = null;
      group = config.services.nginx.group;
    };

    certs."paperless.bobs-home.com" = {
      dnsProvider = "nearlyfreespeech";
      environmentFile = config.age.secrets."nearlyfreespeech".path;
      webroot = null;
      group = config.services.nginx.group;
    };
  };

  # Break the systemd ordering cycle that deadlocks nixos-rebuild switch.
  # DNS-challenge certs don't need nginx running; swap the real acme services
  # out of nginx's After list for the selfsigned fallback services instead.
  # Every domain with enableACME = true in nginx.nix must appear here.
  # FIXME: update this list whenever you add or remove ACME-enabled vhosts.
  systemd.services.nginx.after = lib.mkForce [
    "network.target"
    "acme-selfsigned-bobs-home.com.service"
    "acme-selfsigned-www.bobs-home.com.service"
    "acme-selfsigned-bobs-hobby.com.service"
    "acme-selfsigned-www.bobs-hobby.com.service"
    "acme-selfsigned-hyper.quineglobal.com.service"
    "acme-selfsigned-forge.quinefoundation.com.service"
"acme-selfsigned-webdav.bobs-home.com.service"
    "acme-selfsigned-pluto.bobs-home.com.service"
    "acme-selfsigned-paperless.bobs-home.com.service"
  ];
}
