{ config, lib, pkgs, ... }:
let
  cfg = config.services.matrix-next.sliding-sync;
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf;
in
{
  options.services.matrix-next.sliding-sync = {
    enable = mkEnableOption "the experimental sliding-sync proxy";
    package = mkOption {
      type = types.package;
      description = "The sliding sync proxy package to use";
      default = pkgs.callPackage ../../packages/sliding-sync { };
      defaultText = "pkgs.matrix-next.sliding-sync";
    };

    enableNginx = mkEnableOption "Should this module autogenerate nginx config";
    publicBaseUrl = mkOption {
      type = types.str;
      description = "The domain where clients connect, only has an effect with enableNginx";
      example = "slidingsync.matrix.org";
    };


    server = mkOption {
      type = types.str;
      description = "URL pointing to client endpoints for the matrix server to proxy";
      default = config.services.matrix-synapse.settings.public_baseurl;
      defaultText = lib.literalExpression "config.services.matrix-synapse.settings.public_baseurl";
    };
    bindAddress = mkOption {
      type = types.str;
      description = "The ip and port to listen on";
      default = "0.0.0.0:8007";
    };
    metricsAddress = mkOption {
      type = types.str;
      description = "The ip and port to serve /metrics on";
      default = null;
      example = "0.0.0.0:2112";
    };

    secretFile = mkOption {
      type = types.path;
      description = ''
        A path to a file containing a secret.
        This secret must stay constant for the lifetime of the database
      '';
      example = "/run/secrets/sliding-sync-secret";
    };

    database = {
      host = mkOption {
        type = types.str;
        description = "hostname of database";
        default = "localhost";
      };
      user = mkOption {
        type = types.str;
        description = "user of database";
        default = "matrix-sliding-sync";
      };
      passwordFile = mkOption {
        default = null;
        type = types.nullOr types.path;
        description = "File containing password to connect to database";
      };
      dbname = mkOption {
        type = types.str;
        description = "name of the database";
        default = "matrix-sliding-sync";
      };
      sslmode = mkOption {
        type = types.str;
        default = "disable";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.matrix-sliding-sync = {
      description = "The matrix sliding sync proxy";

      preStart = let
        envFile = pkgs.writeText "sliding-sync-pre-env" ''
          # Automatically generated by nixos
          # Do not edit
          SYNCV3_SECRET=@SYNCV3_SECRET@
          SYNCV3_DB=user=${cfg.database.user} dbname=${cfg.database.dbname} sslmode=${cfg.database.sslmode} ${if cfg.database.passwordFile != null then "password=@DB_PASSWORD@" else ""}
        '';
      in ''
        set -euo pipefail
        install -m 600 ${envFile} /run/sliding-sync/.env
      '' + (if (cfg.secretFile == null) then ''
        if [[ -f /var/lib/matrix-sliding-sync/secretFile ]]; then
            mkdir -p /var/lib/matrix-sliding-sync
            echo -n "$(${pkgs.openssl}/bin/openssl rand -hex 32)" > /var/lib/matrix-sliding-sync/secretFile
        fi

        ${pkgs.replace-secret}/bin/replace-secret '@SYNCV3_SECRET@' "/var/lib/matrix-sliding-sync/secretFile" /run/sliding-sync/.env
      '' else ''
        ${pkgs.replace-secret}/bin/replace-secret '@SYNCV3_SECRET@' '${cfg.secretFile}' /run/sliding-sync/.env
      '') + (if (cfg.database.passwordFile != null) then ''
        ${pkgs.replace-secret}/bin/replace-secret '@DB_PASSWORD@' '${cfg.database.passwordFile}' /run/sliding-sync/.env
      '' else "");
      serviceConfig = {
        User = "matrix-sliding-sync";
        Group = "matrix-sliding-sync";
        DynamicUser = true;
        RuntimeDirectory = "sliding-sync";
        ExecStart = "${cfg.package}/bin/syncv3";
        EnvironmentFile = [ "-/run/sliding-sync/.env" ];
        Environment = [
          "SYNCV3_SERVER=${cfg.server}"
          "SYNCV3_BINDADDR=${cfg.bindAddress}"
        ] ++ lib.optional (cfg.metricsAddress != null) "SYNCV3_PROM=${cfg.metricsAddress}";
      };
    };

    services.nginx.virtualHosts.${cfg.publicBaseUrl} = mkIf cfg.enableNginx {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = lib.replaceStrings [ "0.0.0.0" "::" ] [ "127.0.0.1" "::1" ] "http://${cfg.bindAddress}";
      };
    };
  };
}
