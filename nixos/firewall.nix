{pkgs, ...}: {
  networking.firewall.allowedTCPPorts = [80 22 443];
}
