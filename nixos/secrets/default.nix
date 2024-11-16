{}: let
  mainframePublicKey = builtins.toString "../keys/mainframe.pub";
in {
  #  This .age file should contain the following environment variables:
  #  NEARLYFREESPEECH_API_KEY
  #  NEARLYFREESPEECH_LOGIN
  "./nearlyfreespeech.age".publicKeys = [mainframePublicKey];
}
