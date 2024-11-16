{
  lib,
  pkgs,
  config,
  ...
}: {
  services.nginx = {
    enable = true;

    virtualHosts = {
      "_default" = {
        listen = [
          { addr = "0.0.0.0"; port = 80; }
          { addr = "[::]"; port = 80; }
        ];
        serverName = "_";
        extraConfig = ''
          deny all;
          return 444;
        '';
      };

      "philippeterson.com" = {
        enableACME = true; # Enable Let's Encrypt certificate for HTTPS
        forceSSL = false; # Redirect HTTP to HTTPS?
        addSSL = true;

        root = "/etc/pullomatic/com_philippeterson";

        locations."~ /.git(/.*)$ " = {
          extraConfig = ''
            deny all;
            return 404;
          '';
        };

        locations."~ ^/games/atcsim(/[^/\\s]*)*$" = {
          extraConfig = ''
            index index.html index.htm;
            rewrite ^/games/atcsim/?$ "/index.html" break;
            rewrite ^/games/atcsim(?<query>(/[^/\\s]*)*)$ "$query" break;
            root /etc/pullomatic/atcsim;
          '';
        };

        locations."~ ^/echo(?<query>((/[^/\\s]*)*))$" = {
          extraConfig = ''
            add_header Content-Type text/plain;
            return 200 "$query";
          '';
        };

        locations."/" = {
          extraConfig = ''
            try_files $uri $uri.php $uri/ =404;
            index index.php index.html index.htm;
            rewrite ^/contact$ /contact.php last;
            rewrite ^/resume$ /resume.php last;
          '';
        };

        locations."~ \.php$" = {
          extraConfig = ''
            include ${pkgs.nginx}/conf/fastcgi.conf;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:${config.services.phpfpm.pools.main.socket};
          '';
        };
      };
      "blog.quinefoundation.com" = {
        enableACME = true;
        forceSSL = false;
        addSSL = true;

        root = "/etc/pullomatic/com_quinefoundation_blog/markdown-blog";

        locations."~ /.git(/.*)$ " = {
          extraConfig = ''
            deny all;
            return 404;
          '';
        };

        locations."~ ^/static(/.*)?$" = {
          extraConfig = ''
            autoindex on;
            root /etc/pullomatic/com_quinefoundation_blog/static;
            rewrite ^/static(?<query>(/[^/\\s]*)*)$ "$query" break;
          '';
        };

        locations."/" = {
          extraConfig = ''
            rewrite ^/?$ /blog-posts-list.php last;
            rewrite ^/post/?$ /blog-posts-list.php last;
            rewrite ^/about/?$ /about.php last;
            rewrite ^/credits/?$ /credits.php last;
            rewrite ^/post/([-a-zA-Z0-9]*)$ /blog-page.php?page=$1.md last;
            rewrite ^/rss.xml$ /rss.php last;
            try_files $uri $uri/ =404;
            index index.php index.html index.htm;
          '';
        };

        locations."~ \.php$" = {
          extraConfig = ''
            include ${pkgs.nginx}/conf/fastcgi.conf;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:${config.services.phpfpm.pools.main.socket};
          '';
        };
      };
    };

    # Optionally configure additional options
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  services.phpfpm.pools = {
    main = {
      phpEnv."PATH" = lib.makeBinPath [pkgs.php];
      user = "nginx";
      group = "nginx";
      settings = {
        #         listen = /run/phpfpm.sock
        #         "listen.mode = 0660
        "listen.owner" = "nginx";
        "listen.group" = "nginx";
        "pm" = "dynamic";
        "pm.max_children" = 75;
        "pm.start_servers" = 10;
        "pm.min_spare_servers" = 5;
        "pm.max_spare_servers" = 20;
        "pm.max_requests" = 500;

        "php_admin_value[error_log]" = "stderr";
        "php_admin_flag[log_errors]" = true;
        "catch_workers_output" = true;
      };
    };
  };
}
