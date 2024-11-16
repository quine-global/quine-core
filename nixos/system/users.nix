{
  pkgs,
  config,
  nix-index-database,
  lib,
  ...
}: let
  makeUser = {
    username,
    home,
    extraGroups,
    authorizedKeys,
    homeConfig ? null,
    isNormalUser ? true,
  }: {
    extraGroups = extraGroups ++ [username];

    home-manager.users.${username} = homeConfig;

    users.users.${username} = {
      isNormalUser = isNormalUser;
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = authorizedKeys;
      home = home;
    };

    users.groups.${username} = {
      name = "${username}";
      members = ["${username}"];
    };
  };

  dir = builtins.toString ../keys/authorized_keys;
  files = builtins.attrNames (builtins.readDir dir);
  authorizedKeys = map (file: builtins.readFile "${dir}/${file}") files;

  rootUser = makeUser {
    isNormalUser = false;
    username = "root";
    home = "/root";
    extraGroups = [];
    authorizedKeys = authorizedKeys;
    homeConfig = import ./home/root.nix {
      username = "root";
      inherit config pkgs nix-index-database lib;
    };
  };

  ironmagmaUser = makeUser {
    username = "ironmagma";
    home = "/home/ironmagma";
    extraGroups = [
      "wheel"
      "docker"
    ];
    authorizedKeys = authorizedKeys;
    homeConfig = import ./home/ironmagma.nix {
      username = "ironmagma";
      inherit config pkgs nix-index-database lib;
    };
  };
in {
  users.groups.repo-data = {
    name = "repo-data";
    members = ["nginx"];
  };

  users.users = rootUser.users.users // ironmagmaUser.users.users // {};
  home-manager.users = rootUser.home-manager.users // ironmagmaUser.home-manager.users;
}
