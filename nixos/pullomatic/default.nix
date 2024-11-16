{
  lib,
  pkgs,
  rustPlatform,
  specialArgs,
}:
rustPlatform.buildRustPackage rec {
  pname = "pullomatic";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "philip-peterson";
    repo = pname;
    rev = "master";
    hash = "sha256-VVIhbbdHBBeodODWQq40q91uqtTrUHsCyPgTZ5VtrRc=";
  };

  cargoBuildFlags = ["--bin" "pullomatic"];

  cargoHash = "sha256-oo0M4AlraRw2LRYzvhlbjgvSolZcuRz+2WruesEWltk=";

  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; [
    openssl
  ];

  meta = {
    description = "A tool for automating GitHub pulls";
    homepage = "https://github.com/philip-peterson/pullomatic";
    license = lib.licenses.unlicense;
    maintainers = [
      {
        name = "Philip Peterson";
        email = "peterson@sent.com";
      }
    ];
  };
}
