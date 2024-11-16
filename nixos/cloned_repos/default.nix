{
  pullomatic,
  pkgs,
  lib,
  ...
}: let
  domainToPath = domain: lib.concatStringsSep "_" domain;
  domainToRepoName = domain: lib.concatStringsSep "-" domain;

  makeConfigFile = domain: remoteUrl: branch: {
    name = domainToRepoName domain;
    text = ''
      path: /etc/pullomatic/${domainToPath domain}
      remote_url: ${remoteUrl}
      remote_branch: ${branch}
      interval:
        interval: 10m
      credentials:
        private_key: /root/.ssh/id_rsa.pem
        private_key_path: true
    '';
  };

  configFiles = [
    (makeConfigFile
      ["com" "philippeterson"]
      "git@github.com:philip-peterson/philippeterson.com.git"
      "master")
    (makeConfigFile
      ["com" "quinefoundation" "blog"]
      "git@github.com:philip-peterson/blog.git"
      "master")
    (makeConfigFile
      ["atcsim"]
      "git@github.com:philip-peterson/ATC-Sim.git"
      "master")
  ];

  configDir =
    pkgs.runCommand "config-dir" {
      buildInputs = [pkgs.coreutils];
    } ''
      mkdir -p $out

      # Loop over the config files and write each one to $out
      ${lib.concatStringsSep "\n" (map (cf: ''
          echo "${cf.text}" > $out/${cf.name}
          chmod 0644 $out/${cf.name}
        '')
        configFiles)}

      chmod -R 0750 $out
    '';
in {
  systemd.services.pullomatic = {
    description = "Pull repositories with polling from a daemon";
    serviceConfig = {
      ExecStart = "${pullomatic} -c ${configDir}";
      Restart = "always";
      RestartSec = "0";
      User = "root";
      Group = "root";
    };
  };

  systemd.tmpfiles.rules = [
    "d /etc/pullomatic - root repo-data - -"
    "Z /etc/pullomatic - root repo-data - -"
    "Z /etc/pullomatic/* - root repo-data - -"
  ];
}
