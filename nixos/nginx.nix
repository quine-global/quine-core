{
  lib,
  pkgs,
  config,
  ...
}: {
  services.nginx = {
    enable = true;

    virtualHosts = let
      # Static site embedded in the Nix store at build time.
      # Replace static-site/ with your own files.
      hobbyRoot = pkgs.runCommand "bobs-hobby-web" {} ''
        mkdir -p $out
        cp ${./static-site/index.html} $out/index.html
      '';

      # Wraps a vhost config to also create a www. redirect.
      withWww = domain: cfg: {
        "${domain}" = cfg;
        "www.${domain}" = {
          enableACME = true;
          addSSL = cfg.addSSL or true;
          forceSSL = cfg.forceSSL or false;
          locations."/" = {
            extraConfig = ''
              return 301 https://${domain}$request_uri;
            '';
          };
        };
      };
    in
      {
        # Deny anything that doesn't match a named vhost.
        "_default" = {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
            {
              addr = "[::]";
              port = 80;
            }
          ];
          serverName = "_";
          extraConfig = ''
            deny all;
            return 444;
          '';
        };

        # Quine Global landing page — served from a git repo pulled by pullomatic.
        "quineglobal.com" = {
          enableACME = false;
          forceSSL = false;
          addSSL = false;
          locations."/" = {
            extraConfig = ''
              index index.html index.htm;
              root /etc/pullomatic/com_quineglobal;
            '';
          };
        };

        # Quine Global blog — proxied to a container on port 3010.
        "blog.quineglobal.com" = {
          enableACME = false;
          forceSSL = false;
          addSSL = false;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3010/";
          };
        };

        # Hyper — proxied to a container on port 3013.
        "hyper.quineglobal.com" = {
          enableACME = true;
          forceSSL = false;
          addSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3013/";
          };
        };

        # WebDAV — proxy to the webdav container.
        # FIXME: replace domain
        "webdav.bobs-home.com" = {
          serverName = "webdav.bobs-home.com";
          useACMEHost = "webdav.bobs-home.com";
          onlySSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8082/";
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header Authorization $http_authorization;
              proxy_read_timeout 300;
              proxy_connect_timeout 300;
              proxy_send_timeout 300;
              client_max_body_size 100M;
              proxy_buffering off;
              proxy_cache off;
            '';
          };
        };

        # Paperless-ngx document management.
        # FIXME: replace domain
        "paperless.bobs-home.com" = {
          useACMEHost = "paperless.bobs-home.com";
          onlySSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8000/";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
              proxy_read_timeout 86400;
              client_max_body_size 100M;
            '';
          };
        };

        # Pluto — Julia notebook server.
        # FIXME: replace domain
        "pluto.bobs-home.com" = {
          useACMEHost = "pluto.bobs-home.com";
          onlySSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:1234/";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
              proxy_set_header Host $host;
              proxy_read_timeout 86400;
            '';
          };
        };

        # Forgejo git forge — HTTPS vhost.
        "forge.quinefoundation.com-https" = {
          serverName = "forge.quinefoundation.com";
          enableACME = true;
          onlySSL = true;
          extraConfig = ''
            client_max_body_size 0;
          '';
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000/";
          };
        };

        # Forgejo — HTTP vhost that redirects to HTTPS.
        "forge.quinefoundation.com-http" = {
          serverName = "forge.quinefoundation.com";
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
            {
              addr = "[::]";
              port = 80;
            }
          ];
          locations."/" = {
            extraConfig = ''
              return 302 https://$host$request_uri;
            '';
          };
        };
      }
      # Personal site with PHP — served from a git repo pulled by pullomatic.
      # FIXME: replace domain and adjust URL rewrite rules for your site.
      // (withWww "bobs-home.com" {
        enableACME = true;
        forceSSL = false;
        addSSL = true;
        root = "/etc/pullomatic/com_bobs-home";
        locations."~ /.git(/.*)$ " = {
          extraConfig = ''
            deny all;
            return 404;
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
      })
      # Static hobby site served directly from the Nix store.
      # FIXME: replace domain and put your files in static-site/
      // (withWww "bobs-hobby.com" {
        enableACME = true;
        forceSSL = false;
        addSSL = true;
        root = hobbyRoot;
      });

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
