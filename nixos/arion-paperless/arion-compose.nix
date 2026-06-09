{ pkgs, ... }:
{
  project.name = "paperless";

  networks.paperless.external = false;

  services = {
    redis = {
      service = {
        image = "redis:7";
        container_name = "paperless-redis";
        restart = "unless-stopped";
        networks = ["paperless"];
        volumes = [
          "/var/paperless/redis:/data"
        ];
      };
    };

    db = {
      service = {
        image = "postgres:16";
        container_name = "paperless-db";
        restart = "unless-stopped";
        networks = ["paperless"];
        volumes = [
          "/var/paperless/postgres:/var/lib/postgresql/data"
        ];
        environment = {
          POSTGRES_DB = "paperless";
          POSTGRES_USER = "paperless";
          POSTGRES_PASSWORD = "paperless";
        };
        healthcheck = {
          test = ["CMD-SHELL" "pg_isready -U paperless -d paperless"];
          interval = "5s";
          timeout = "5s";
          retries = 20;
        };
      };
    };

    webserver = {
      service = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
        container_name = "paperless-ngx";
        restart = "unless-stopped";
        networks = ["paperless"];
        depends_on = ["db" "redis"];
        ports = ["127.0.0.1:8000:8000"];
        volumes = [
          "/var/paperless/data:/usr/src/paperless/data"
          "/var/paperless/media:/usr/src/paperless/media"
          "/var/paperless/export:/usr/src/paperless/export"
          "/var/paperless/consume:/usr/src/paperless/consume"
        ];
        environment = {
          PAPERLESS_REDIS = "redis://redis:6379";
          PAPERLESS_DBHOST = "db";
          PAPERLESS_DBNAME = "paperless";
          PAPERLESS_DBUSER = "paperless";
          PAPERLESS_DBPASS = "paperless";
          # FIXME: replace with your actual domain
          PAPERLESS_URL = "https://paperless.bobs-home.com";
          PAPERLESS_TIME_ZONE = "America/Chicago";
          PAPERLESS_OCR_LANGUAGE = "eng";
          USERMAP_UID = "1000";
          USERMAP_GID = "1000";
        };
        env_file = ["/run/agenix/paperless"];
      };
    };
  };
}
