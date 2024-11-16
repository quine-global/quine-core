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
    homeDirectory = "/root";
  };
in {
  imports = [shared];

  home.sessionVariables.EDITOR = "vim";
}
