let
  mainframePublicKey = builtins.readFile ../keys/mainframe.pub;
in {
  # NEARLYFREESPEECH_API_KEY, NEARLYFREESPEECH_LOGIN
  # Used for DNS-challenge ACME cert provisioning via the NearlyFreeSpeech DNS provider.
  "./nearlyfreespeech.age".publicKeys = [mainframePublicKey];

  # WEBDAV_PASSWORD
  "./webdav.age".publicKeys = [mainframePublicKey];

  # ANTHROPIC_API_KEY (optional — only needed if you use claude-code or other Anthropic tools)
  "./anthropic-api-key.age".publicKeys = [mainframePublicKey];

  # TOKEN=<forgejo runner registration token from Forgejo admin>
  "./forgejo-runner-token.age".publicKeys = [mainframePublicKey];

  # PAPERLESS_SECRET_KEY=<long random string>
  # PAPERLESS_ADMIN_USER=admin
  # PAPERLESS_ADMIN_PASSWORD=<password>
  # PAPERLESS_ADMIN_EMAIL=<email>
  "./paperless.age".publicKeys = [mainframePublicKey];

  # Add any app-specific secrets here, e.g.:
  # DATABASE_URL=<postgres dsn>
  # APP_SECRET=<secret>
  # "./my-webapp.age".publicKeys = [mainframePublicKey];
}
