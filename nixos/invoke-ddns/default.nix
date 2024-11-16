{pkgs ? import <nixpkgs> {}, ...}: let
  # Fetch the tarball
  nfsn_ddns_tarball = pkgs.fetchurl {
    url = "https://files.pythonhosted.org/packages/76/15/607b52a0bfda95fd8157c1c4b3b3631aa535206b2bd8fb43f57961460402/nfsn_ddns-0.2.0.tar.gz";
    sha256 = "sha256-ijD3hrdoYNt/MHy4C6zIqgU5sj+kGg+ma8TswO5qOEk=";
  };

  # Extract the tarball
  extracted_nfsn_ddns = pkgs.stdenv.mkDerivation {
    name = "nfsn-ddns-extracted";

    src = nfsn_ddns_tarball;

    buildInputs = [pkgs.gnugrep pkgs.gnumake pkgs.gzip]; # Ensure tools are available for extraction if needed

    phases = ["unpackPhase" "installPhase"];

    unpackPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out
    '';

    installPhase = ''
      echo "Extracted files available in $out"
    '';

    meta = with pkgs.lib; {
      description = "Extracted files from nfsn_ddns tarball";
      license = licenses.unlicense;
      maintainers = [];
    };
  };
in
  pkgs.python3Packages.buildPythonApplication rec {
    pname = "invoke-ddns";
    version = "0.0.1";

    src = ./.;

    format = "setuptools";

    dontUseCmakeConfigure = true;

    buildInputs = with pkgs.python3Packages; [
      setuptools
      extracted_nfsn_ddns
    ];

    propagatedBuildInputs = with pkgs.python3Packages; [
      tornado
      requests
      python-daemon
      pip
      pykka
      pytest
    ];

    # no tests implemented
    #doCheck = false;
    #pythonImportsCheck = [ "mopidy_jellyfin" ];

    meta = with pkgs.lib; {
      homepage = "https://github.com/philip-peterson/invoke-ddns";
      description = "Invoke DDNS for fun and profit";
      license = licenses.unlicense;
      maintainers = ["Philip Peterson"];
    };
  }
