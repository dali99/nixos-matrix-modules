{ lib, pkgs, config, ... }:

let
  cfg = config.services.matrix-synapse-next;
  format = pkgs.formats.yaml {};
  matrix-synapse-common-config = format.generate "matrix-synapse-common-config.yaml" cfg.settings;
  pluginsEnv = cfg.package.python.buildEnv.override {
    extraLibs = cfg.plugins;
  };
in
{
  options.services.matrix-synapse-next = {
    enable = lib.mkEnableOption "matrix-synapse";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.matrix-synapse;
    };
    
    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExample ''
        with config.services.matrix-synapse-advanced.package.plugins; [
          matrix-synapse-ldap3
          matrix-synapse-pam
        ];
      '';
      description = ''
        List of additional Matrix plugins to make available.
      '';
    };
    
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/matrix-synapse";
      description = ''
        The directory where matrix-synapse stores its stateful data such as
        certificates, media and uploads.
      '';
    };

    mainLogConfig = lib.mkOption {
      type = lib.types.lines;
      description = "A yaml python logging config file";
      default = lib.readFile ./matrix-synapse-log_config.yaml;
    };

    workers = let
      isReplication = l: lib.lists.any (r: lib.lists.any (n: n == "replication") r.names) l.resources;

      dMRL = lib.lists.findFirst isReplication
        (throw "No replication listener configured!")
        cfg.settings.listeners;

      dMRH = lib.findFirst (x: true) (throw "Replication listener had no addresses")
        dMRL.bind_addresses;
      dMRP = dMRL.port;
    in {
      mainReplicationHost = lib.mkOption {
        type = lib.types.str;
        default = if builtins.elem dMRH [ "0.0.0.0" "::" ] then "127.0.0.1" else dMRH;
        description = "Host of the main synapse instance's replication listener";
      };

      mainReplicationPort = lib.mkOption {
        type = lib.types.port;
        default = dMRP;
        description = "Port for the main synapse instance's replication listener";
      };

      defaultListenerAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "The default listener address for the worker";
      };

      workerStartingPort = lib.mkOption {
        type = lib.types.port;
        description = "What port should the automatically configured workers start enumerating from";
        default = 8083;
      };

      federationSenders = lib.mkOption {
        type = lib.types.ints.unsigned;
        description = "How many automatically configured federation senders to set up";
        default = 0;
      };

      federationReceivers = lib.mkOption {
        type = lib.types.ints.unsigned;
        description = "How many automatically configured federation recievers to set up";
        default = 0;
      };

      instances = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({config, ...}: {

          options.autoType = lib.mkOption {
            type = lib.types.enum [ null "fed-sender" "fed-receiver" ];
            internal = true;
            default = null;
          };

          options.settings = let
            instanceCfg = config;
            inherit (instanceCfg) autoType autoPort;

            isAuto = autoType != null;

            mapTypeApp = t: {
              "fed-sender"   = "synapse.app.federation_sender";
              "fed-receiver" = "synapse.app.generic_worker";
            }.${t};

            defaultApp = if (instanceCfg.autoType == null)
              then "synapse.app.generic_worker"
              else mapTypeApp instanceCfg.autoType;

            typeToResources = t: {
              "fed-receiver" = [ "federation" ];
              "fed-sender"   = [ ];
            }.${t};
          in lib.mkOption {
            type = lib.types.submodule ({config, ...}: {
              freeformType = format.type;
            
              options.worker_app = lib.mkOption {
                type = lib.types.enum [
                  "synapse.app.generic_worker"
                  "synapse.app.pusher"
                  "synapse.app.appservice"
                  "synapse.app.federation_sender"
                  "synapse.app.media_repository"
                  "synapse.app.user_dir"
                ];
                description = "The type of worker application";
                default = defaultApp;
              };
              options.worker_replication_host = lib.mkOption {
                type = lib.types.str;
                default = cfg.workers.mainReplicationHost;
                description = "The replication listeners ip on the main synapse process";
              };
              options.worker_replication_http_port = lib.mkOption {
                type = lib.types.port;
                default = cfg.workers.mainReplicationPort;
                description = "The replication listeners port on the main synapse process";
              };
              options.worker_listeners = lib.mkOption {
                type = lib.types.listOf (lib.types.submodule {
                  options.type = lib.mkOption {
                    type = lib.types.enum [ "http" "metrics" ];
                    description = "The type of the listener";
                    default = "http";
                  };
                  options.port = lib.mkOption {
                    type = lib.types.port;
                    description = "the TCP port to bind to";
                  };
                  options.bind_addresses = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    description = "A list of local addresses to listen on";
                    default = [ cfg.workers.defaultListenerAddress ];
                  };
                  options.tls = lib.mkOption {
                    type = lib.types.bool;
                    description = "set to true to enable TLS for this listener. Will use the TLS key/cert specified in tls_private_key_path / tls_certificate_path.";
                    default = false;
                  };
                  options.x_forwarded = lib.mkOption {
                    type = lib.types.bool;
                    description = ''
                      Only valid for an 'http' listener. Set to true to use the X-Forwarded-For header as the client IP.
                      Useful when Synapse is behind a reverse-proxy.
                    '';
                    default = true;
                  };
                  options.resources = lib.mkOption {
                    type = lib.types.listOf (lib.types.submodule {
                      options.names = lib.mkOption {
                        type = lib.types.listOf (lib.types.enum [ "client" "consent" "federation" "keys" "media" "metrics" "openid" "replication" "static" "webclient" ]);
                        description = "A list of resources to host on this port";
                        default = lib.optionals isAuto (typeToResources instanceCfg.autoType);
                      };
                      options.compress = lib.mkOption {
                        type = lib.types.bool;
                        description = "enable HTTP compression for this resource";
                        default = false;
                      };
                    });
                    default = [{ }];
                  };
                });
                description = "Listener configuration for the worker, similar to the main synapse listener";
                default = [ ];
              };
            });
          };
        }));
        default = { };
        description = "Worker configuration";
        example = {
          "federation_sender1" = {
            settings = {
              worker_name = "federation_sender1";
              worker_app = "synapse.app.federation_sender";

              worker_replication_host = "127.0.0.1";
              worker_replication_http_port = 9093;
              worker_listeners = [ ];
            };
        };
      };
    };
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = format.type;

        options.server_name = lib.mkOption {
          type = lib.types.str;
          description = ''
            The server_name name will appear at the end of usernames and room addresses
            created on this server. For example if the server_name was example.com,
            usernames on this server would be in the format @user:example.com
            
            In most cases you should avoid using a matrix specific subdomain such as
            matrix.example.com or synapse.example.com as the server_name for the same
            reasons you wouldn't use user@email.example.com as your email address.
            See https://github.com/matrix-org/synapse/blob/master/docs/delegate.md
            for information on how to host Synapse on a subdomain while preserving
            a clean server_name.
            
            The server_name cannot be changed later so it is important to
            configure this correctly before you start Synapse. It should be all
            lowercase and may contain an explicit port.
          '';
          example = "matrix.org";
        };

        options.use_presence = lib.mkOption {
          type = lib.types.bool;
          description = "disable presence tracking, if you're having perfomance issues this can have a big impact";
          default = true;
        };

        options.listeners = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule {
            options.port = lib.mkOption {
              type = lib.types.port;
              description = "the TCP port to bind to";
              example = 8448;
            };
            options.bind_addresses = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "A list of local addresses to listen on";
            };
            options.type = lib.mkOption {
              type = lib.types.enum [ "http" "manhole" "metrics" "replication" ];
              description = "The type of the listener";
              default = "http";
            };
            options.tls = lib.mkOption {
              type = lib.types.bool;
              description = "set to true to enable TLS for this listener. Will use the TLS key/cert specified in tls_private_key_path / tls_certificate_path.";
              default = true;
            };
            options.x_forwarded = lib.mkOption {
              type = lib.types.bool;
              description = ''
                Only valid for an 'http' listener. Set to true to use the X-Forwarded-For header as the client IP.
                Useful when Synapse is behind a reverse-proxy.
              '';
              default = false;
            };
            options.resources = lib.mkOption {
              type = lib.types.listOf (lib.types.submodule {
                options.names = lib.mkOption {
                  type = lib.types.listOf (lib.types.enum [ "client" "consent" "federation" "keys" "media" "metrics" "openid" "replication" "static" "webclient" ]);
                  description = "A list of resources to host on this port";
                };
                options.compress = lib.mkOption {
                  type = lib.types.bool;
                  description = "enable HTTP compression for this resource";
                  default = false;
                };
              });
            };
          });
          description = "List of ports that Synapse should listen on, their purpose and their configuration";
          default = let enableReplication = lib.lists.any
            (w: !(builtins.elem w.settings.worker_app [ "federationSender" ]))
            cfg.workers.instances;
          in [
            {
              port = 8008;
              bind_addresses = [ "127.0.0.1" ];
              resources = [
                { names = [ "client" ]; compress = true; }
                { names = [ "federation" ]; compress = false; }
              ];
            }
            (lib.mkIf enableReplication {
              port = 9093;
              bind_addresses = [ "127.0.0.1" ];
              resources = [
                {  names = [ "replication" ]; }
              ];
            })
          ];
        };

        options.federation_ip_range_blacklist = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = ''
            Prevent federation requests from being sent to the following
            blacklist IP address CIDR ranges. If this option is not specified, or
            specified with an empty list, no ip range blacklist will be enforced.
          '';
          default = [
            "127.0.0.0/8"
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
            "100.64.0.0/10"
            "169.254.0.0/16"
            "::1/128"
            "fe80::/64"
            "fc00::/7"
          ];
        };
        options.log_config = lib.mkOption {
          type = lib.types.path;
          description = ''
            A yaml python logging config file as described by
            https://docs.python.org/3.7/library/logging.config.html#configuration-dictionary-schema
          '';
          default = pkgs.writeText "log_config.yaml" cfg.mainLogConfig;
        };

        options.media_store_path = lib.mkOption {
          type = lib.types.path;
          description = "Directory where uploaded images and attachments are stored";
          default = "${cfg.dataDir}/media_store";
        };
        options.max_upload_size = lib.mkOption {
          type = lib.types.str;
          description = "The largest allowed upload size in bytes";
          default = "50M";
        };

        options.enable_registration = lib.mkOption {
          type = lib.types.bool;
          description = "Enable registration for new users";
          default = false;
        };

        options.enable_metrics = lib.mkOption {
          type = lib.types.bool;
          description = "Enable collection and rendering of performance metrics";
          default = false;
        };
        options.report_stats = lib.mkOption {
          type = lib.types.bool;
          description = "TODO: Enable and Disable reporting usage stats";
          default = false;
        };

        options.app_service_config_files = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          description = "A list of application service config files to use";
          default = [];
        };

        options.signing_key_path = lib.mkOption {
          type = lib.types.path;
          description = "Path to the signing key to sign messages with";
          default = "${cfg.dataDir}/homeserver.signing.key";
        };

        options.trusted_key_servers = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule {
            freeformType = format.type;

            options.server_name = lib.mkOption {
              type = lib.types.str;
              description = "the name of the server. required";
            };
          });
          description = "The trusted servers to download signing keys from";
          default = [
            {
              server_name = "matrix.org";
              verify_keys."ed25519:auto" = "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw";
            }
          ];
        };
        
        options.send_federation = lib.mkOption {
          type = lib.types.bool;
          description = "Disables sending of outbound federation transactions on the main process. Set to false if using federation senders";
          default = cfg.settings.federation_sender_instances == [];
        };

        options.federation_sender_instances = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = ''
            This configuration must be shared between all federation sender workers, and if
            changed all federation sender workers must be stopped at the same time and then
            started, to ensure that all instances are running with the same config (otherwise
            events may be dropped)
          '';
          default = [ ];
        };

        options.redis = lib.mkOption {
          type = lib.types.submodule {
            freeformType = format.type;

            options.enabled = lib.mkOption {
              type = lib.types.bool;
              description = "Enables using redis, required for worker support";
              default = (lib.lists.count (x: true)
                (lib.attrsets.attrValues cfg.workers.instances)) > 0;
            };
          };
          default = { };
          description = "configuration of redis for synapse and workers"; 
        };
      };
    };

    extraConfigFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = ''
        Extra config files to include.
        The configuration files will be included based on the command line
        argument --config-path. This allows to configure secrets without
        having to go through the Nix store, e.g. based on deployment keys if
        NixOPS is in use.
      '';
    };

  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    ({
      users.users.matrix-synapse = {
        group = "matrix-synapse";
        home = cfg.dataDir;
        createHome = true;
        shell = "${pkgs.bash}/bin/bash";
        uid = config.ids.uids.matrix-synapse;
      };
      users.groups.matrix-synapse = {
        gid = config.ids.gids.matrix-synapse;
      };
      systemd.targets.matrix-synapse = {
        description = "Synapse parent target";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    })

    (lib.mkIf cfg.enableMainSynapse {
      systemd.services.matrix-synapse = {
        description = "Synapse Matrix homeserver";
        partOf = [ "matrix-synapse.target" ];
        wantedBy = [ "matrix-synapse.target" ];
        preStart = ''
        ${cfg.package}/bin/synapse_homeserver \
          ${ lib.concatMapStringsSep "\n  " (x: "--config-path ${x} \\") ([ matrix-synapse-common-config ] ++ cfg.extraConfigFiles) }
          --keys-directory ${cfg.dataDir} \
          --generate-keys
      '';
        environment.PYTHONPATH = lib.makeSearchPathOutput "lib" cfg.package.python.sitePackages [ pluginsEnv ];
        serviceConfig = {
          Type = "notify";
          User = "matrix-synapse";
          Group = "matrix-synapse";
          WorkingDirectory = cfg.dataDir;
          ExecStart = ''
            ${cfg.package}/bin/synapse_homeserver \
              ${ lib.concatMapStringsSep "\n  " (x: "--config-path ${x} \\") ([ matrix-synapse-common-config ] ++ cfg.extraConfigFiles) }
              --keys-directory ${cfg.dataDir}
          '';
          ExecReload = "${pkgs.utillinux}/bin/kill -HUP $MAINPID";
          Restart = "on-failure";
        };
      };
    })

    (lib.mkMerge [
      ({
        services.matrix-synapse-next.settings.federation_sender_instances = lib.genList (x: "auto-fed-sender${toString x}") cfg.workers.federationSenders;

        services.matrix-synapse-next.workers.instances = lib.attrsets.genAttrs (lib.genList
          (x: "auto-fed-sender${toString x}") cfg.workers.federationSenders)
          (_: { autoType = "fed-sender"; });
      })

      ({
        services.matrix-synapse-next.workers.instances = let 
          genAttrs' = items: f: g: builtins.listToAttrs (builtins.map (n: lib.attrsets.nameValuePair (f n) (g n)) items);
        in genAttrs' (lib.genList (x: x) cfg.workers.federationReceivers)
          (x: "auto-fed-receiver${builtins.toString x}")
          (x: {
            autoType = "fed-receiver";
            settings.worker_listeners = [{ port = cfg.workers.workerStartingPort + x; }];
          });
      })
    ])

    ({
      systemd.services = let
        workerList = lib.mapAttrsToList (name: value: lib.nameValuePair name value ) cfg.workers.instances;
        workerName = worker: worker.name;
        workerSettings = worker: (worker.value.settings // {worker_name = (workerName worker);});
        workerConfig = worker: format.generate "matrix-synapse-worker-${workerName worker}-config.yaml" (workerSettings worker);
      in builtins.listToAttrs (map (worker:
        {
          name = "matrix-synapse-worker-${workerName worker}";
          value = {
            description = "Synapse Matrix Worker";
            partOf = [ "matrix-synapse.target" ];
            wantedBy = [ "matrix-synapse.target" ];
            after = [ "matrix-synapse.service" ];
            requires = [ "matrix-synapse.service" ];
            environment.PYTHONPATH = lib.makeSearchPathOutput "lib" cfg.package.python.sitePackages [
              pluginsEnv
            ];
            serviceConfig = {
              Type = "notify";
              User = "matrix-synapse";
              Group = "matrix-synapse";
              WorkingDirectory = cfg.dataDir;
              ExecStartPre = pkgs.writers.writeBash "wait-for-synapse" ''
                # From https://md.darmstadt.ccc.de/synapse-at-work
                while ! systemctl is-active -q matrix-synapse.service; do
                    sleep 1
                done
              '';
              ExecStart = ''
                ${cfg.package}/bin/synapse_worker \
                  ${ lib.concatMapStringsSep "\n  " (x: "--config-path ${x} \\") ([ matrix-synapse-common-config (workerConfig worker) ] ++ cfg.extraConfigFiles) }
                  --keys-directory ${cfg.dataDir}
              '';
            };
          };
        }
      ) workerList);
    })
  ]);
}