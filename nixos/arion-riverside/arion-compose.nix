{ pkgs, ... }:
{
  # Example multi-service web app: WordPress + MySQL.
  # Replace the image and env vars for your own application.
  project.name = "riverside";

  networks.riverside.external = false;

  services = {
    app = {
      service = {
        # FIXME: replace with your actual application image
        image = "wordpress:6-php8.2-apache";
        container_name = "my-webapp";
        restart = "unless-stopped";
        networks = ["riverside"];
        environment = {
          WORDPRESS_DB_HOST = "db";
          WORDPRESS_DB_NAME = "wordpress";
          WORDPRESS_DB_USER = "wordpress";
          WORDPRESS_DB_PASSWORD = "wordpress";
        };
        volumes = [
          "/var/riverside/files:/var/www/html/wp-content"
        ];
        ports = ["3011:80"];
        depends_on = ["db"];
      };
    };

    db = {
      service = {
        image = "mysql:8";
        container_name = "my-webapp-db";
        restart = "unless-stopped";
        networks = ["riverside"];
        environment = {
          MYSQL_DATABASE = "wordpress";
          MYSQL_USER = "wordpress";
          MYSQL_PASSWORD = "wordpress";
          MYSQL_RANDOM_ROOT_PASSWORD = "1";
        };
        volumes = [
          "/var/riverside/db:/var/lib/mysql"
        ];
        healthcheck = {
          test = ["CMD-SHELL" "mysqladmin ping -h localhost"];
          interval = "5s";
          timeout = "5s";
          retries = 20;
        };
      };
    };
  };
}
