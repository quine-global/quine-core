{pkgs, ...}: {
  networking.firewall.allowedTCPPorts = [
    80 # nginx/http
    22 # ssh
    443 # ssl

    2200 # forgejo ssh
    3000 # forgejo http

    8082 # webdav
  ];

  # Allow DNS from all podman bridge networks (10.89.0.0/16).
  # NixOS auto-adds a rule for podman0 but not for networks created by
  # docker-compose/arion (podman1, podman2, …).
  networking.firewall.extraCommands = ''
    iptables -I nixos-fw -s 10.89.0.0/16 -p udp --dport 53 -j nixos-fw-accept
    iptables -I nixos-fw -s 10.89.0.0/16 -p tcp --dport 53 -j nixos-fw-accept
    iptables -I nixos-fw -s 10.89.0.0/16 -p tcp --dport 5901 -j nixos-fw-accept
  '';
}
