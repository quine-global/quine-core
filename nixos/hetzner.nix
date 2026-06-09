{modulesPath, ...}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Fixes iotop
  boot.kernel.sysctl = {"kernel.task_delayacct" = 1;};

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    efiSupport = false;
  };

  # FIXME: replace with your actual disk UUID (find with: lsblk -f)
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/YOUR-DISK-UUID-HERE";
    fsType = "ext4";
  };

  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    # FIXME: replace enp1s0 with your actual NIC name (check with: ip link)
    networks."10-enp1s0" = {
      matchConfig.Name = "enp1s0";
      networkConfig.DHCP = "ipv4";
      dhcpV4Config = {
        UseGateway = false;
        UseRoutes = false;
      };
      routes = [
        {routeConfig = {Gateway = "172.31.1.1"; GatewayOnLink = true;};}
      ];
    };
  };

  services.openssh = {
    enable = true;
    # FIXME: set to false once your SSH keys are in place
    settings.PasswordAuthentication = true;
    settings.PermitRootLogin = "yes";
    settings.AllowUsers = ["root"];
    extraConfig = ''
      PrintLastLog no
    '';
    hostKeys = [
      {
        bits = 4096;
        path = "/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
      }
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }

      # For secrets decryption (agenix)
      {
        path = "/root/.ssh/id_rsa_nix";
        type = "ed25519";
      }
    ];
  };
}
