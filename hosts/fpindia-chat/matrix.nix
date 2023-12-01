{ pkgs, config, ... }:
let
  # fqdn = "${config.networking.hostName}.${config.networking.domain}";
  domain = "functionalprogramming.in";
  fqdn = "ems.${domain}";
  baseUrl = "https://${fqdn}";

  # NOTE: Both these configs must be aligned with the ".well-known" routes
  # We currently servce these from the static site; https://github.com/fpindia/fpindia-site/pull/44/files
  clientConfig."m.homeserver" = {
    base_url = baseUrl;
    server_name = "${domain}";
  };
  serverConfig."m.server" = "${fqdn}:443";
in
{
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.postgresql.enable = true;
  services.postgresql.initialScript = pkgs.writeText "synapse-init.sql" ''
    CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
    CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
      TEMPLATE template0
      LC_COLLATE = "C"
      LC_CTYPE = "C";
  '';

  # Staged here so admin can manually serve these from the appropriate place
  environment.etc = {
    "matrix-well-known/server".text = builtins.toJSON serverConfig;
    "matrix-well-known/client".text = builtins.toJSON clientConfig;
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    virtualHosts = {
      # NOTE: Main domain is hosted by GitHub: https://github.com/fpindia/fpindia-site

      "${fqdn}" = {
        enableACME = true;
        forceSSL = true;
        # It's also possible to do a redirect here or something else, this vhost is not
        # needed for Matrix. It's recommended though to *not put* element
        # here, see also the section about Element.
        locations."/".extraConfig = ''
          return 404;
        '';
        # Forward all Matrix API calls to the synapse Matrix homeserver. A trailing slash
        # *must not* be used here.
        locations."/_matrix".proxyPass = "http://[::1]:8008";
        # Forward requests for e.g. SSO and password-resets.
        locations."/_synapse/client".proxyPass = "http://[::1]:8008";
      };

      "chat.${domain}" = {
        enableACME = true;
        forceSSL = true;

        root = pkgs.element-web.override {
          conf = {
            default_server_config = clientConfig; # see `clientConfig` from the snippet above.
          };
        };
      };

    };
  };

  # To create this key, consult: https://nixos.org/manual/nixos/stable/index.html#module-services-matrix-synapse
  deployment.keys."matrix-shared-secret.secret" = {
    keyCommand = [ "op" "read" "op://Juspay/fpindia-chat secrets/matrix-shared-secret" ];
    user = config.systemd.services.matrix-synapse.serviceConfig.User;
  };
  systemd.services.matrix-synapse.serviceConfig.SupplementaryGroups = [ "keys" ]; # For colmera

  services.matrix-synapse = {
    enable = true;
    settings.server_name = domain;
    settings.enable_registration = true;
    settings.enable_registration_captcha = true;
    extraConfigFiles = [
      "/run/keys/matrix-shared-secret.secret"
    ];

    # The public base URL value must match the `base_url` value set in `clientConfig` above.
    # The default value here is based on `server_name`, so if your `server_name` is different
    # from the value of `fqdn` above, you will likely run into some mismatched domain names
    # in client applications.
    settings.public_baseurl = baseUrl;
    settings.listeners = [
      {
        port = 8008;
        bind_addresses = [ "::1" ];
        type = "http";
        tls = false;
        x_forwarded = true;
        resources = [{
          names = [ "client" "federation" ];
          compress = true;
        }];
      }
    ];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "srid@srid.ca";
  };
}
