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
        username: git
        private_key:
          file: /root/.ssh/id_rsa.pem
    '';
  };

  # FIXME: replace these with your own repositories
  configFiles = [
    (makeConfigFile
      ["com" "bobs-home"]
      "git@github.com:bob-smith/bobs-website.git"
      "main")
    (makeConfigFile
      ["com" "bobs-global"]
      "git@github.com:bob-smith/landing-page.git"
      "main")
  ];

  configDir =
    pkgs.runCommand "config-dir" {
      buildInputs = [pkgs.coreutils];
    } ''
      mkdir -p $out

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
      Group = "repo-data";
    };
  };

  systemd.tmpfiles.rules = [
    "d /etc/pullomatic - root repo-data - -"
    "Z /etc/pullomatic - root repo-data - -"
    "Z /etc/pullomatic/* - root repo-data - -"
  ];
}
