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

  startSeq = builtins.fromJSON ''"\u001b[7m"''; # Start inverted color
  endSeq = builtins.fromJSON ''"\u001b[27m"''; # End inverted color
  motd = "${startSeq} Welcome to the Peterson Mainframe! Look, touch, but DO NOT LICK. ${endSeq}";

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
    (import ./nginx.nix {inherit pkgs lib config;})
    (import ./firewall.nix {inherit pkgs;})
    (import ./system/users.nix {inherit pkgs config lib nix-index-database;})
  ];

  time.timeZone = "America/Anchorage";

  age.secrets.nearlyfreespeech.file = ./secrets/nearlyfreespeech.age;
  age.secrets.nearlyfreespeech.owner = "root";

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
  ];

  swapDevices = [
    {
      device = "/swapfile";
      size = 1 * 1024; # 1GB
    }
  ];

  systemd.tmpfiles.rules = [
    "d /home/ironmagma/.config 0755 ${username} users"
    "d /root/.config 0755 ${username} users"
  ];

  networking.hostName = "${hostname}";

  # FIXME: change your shell here if you don't want zsh
  programs.zsh.enable = true;
  environment.pathsToLink = ["/share/zsh"];
  environment.shells = [pkgs.zsh];

  environment.enableAllTerminfo = true;

  security.sudo.wheelNeedsPassword = false;

  users.motd = motd;

  system.stateVersion = "22.05";

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  virtualisation.oci-containers = {
    backend = "docker";

    containers = {
      "hello" = {
        autoStart = true;
        image = "nginxdemos/hello";
        #user = "root:jellyfin";
        volumes = [
        ];
        ports = ["8081:80"];
      };

      "navidrome" = {
        autoStart = true;
        environment = {
          "TZ" = "America/Anchorage";
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
        #user = "root:jellyfin";
        volumes = [
          "/mnt/webdav/data:/data"
          "/mnt/webdav/config:/config"
        ];
        environment = {
          "WEBDAV_USERNAME" = "foo";
          # TODO
          "WEBDAV_PASSWORD" = "bar";
          "TZ" = "America/Anchorage";

          "PUID" = "60"; # nginx user
          "PGID" = "60"; # nginx group
        };
        ports = ["8082:80"];
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

    package = pkgs.nixFlakes;
    extraOptions = ''experimental-features = nix-command flakes'';

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  # HTTPS

  security.acme = {
    acceptTerms = true;
    defaults.email = "peterson@sent.com";
    certs."philippeterson.com" = {
      dnsProvider = "nearlyfreespeech";
      environmentFile = config.age.secrets."nearlyfreespeech".path;
      webroot = null;
    };
  };
}
