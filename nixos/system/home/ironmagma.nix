{
  config,
  pkgs,
  username,
  nix-index-database,
  lib,
  ...
}: let
  shared = import ./shared.nix {
    inherit config pkgs username nix-index-database lib;
    homeDirectory = "/home/ironmagma";
  };
in {
  imports = [shared];
}
