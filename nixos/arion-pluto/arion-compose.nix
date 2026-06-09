{ pkgs, ... }:
{
  project.name = "pluto";

  networks.pluto.external = false;

  services = {
    app = {
      service = {
        image = "julia:1.11";
        container_name = "pluto";
        restart = "unless-stopped";
        networks = ["pluto"];
        command = [
          "sh"
          "-c"
          "julia -e 'using Pkg; Pkg.add(\"Pluto\"); import Pluto; Pluto.run(host=\"0.0.0.0\", port=1234, launch_browser=false)'"
        ];
        volumes = [
          "/var/pluto/notebooks:/notebooks"
          "/var/pluto/julia-depot:/root/.julia"
        ];
        environment = {
          JULIA_NUM_THREADS = "auto";
        };
        ports = ["127.0.0.1:1234:1234"];
      };
    };
  };
}
