{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.homebox;
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkDefault
    mkOption
    types
    mkIf
    ;
in
{
  options.services.homebox = {
    enable = mkEnableOption "homebox";
    package = mkPackageOption pkgs "homebox" { };
    user = mkOption {
      type = types.str;
      default = "homebox";
      description = "User account under which Homebox runs.";
    };
    group = mkOption {
      type = types.str;
      default = "homebox";
      description = "Group under which Homebox runs.";
    };
      settings = mkOption {
        type = types.submodule {
          # Allow arbitrary environment variables in addition to the structured ones below
          freeformType = with types; attrsOf str;

          options = {
            HBOX_STORAGE_CONN_STRING = mkOption {
              type = types.str;
              default = "file:///var/lib/homebox";
              description = "Storage backend connection string (e.g., file:///var/lib/homebox).";
            };
            HBOX_STORAGE_PREFIX_PATH = mkOption {
              type = types.str;
              description = "Prefix path within the storage backend (e.g., data).";
              default = ".data";
            };
            HBOX_DATABASE_DRIVER = mkOption {
              type = types.enum [ "sqlite3" "postgres" ];
              default = "sqlite3";
              description = "Database driver to use (sqlite3 or postgres).";
            };
            HBOX_DATABASE_SQLITE_PATH = mkOption {
              type = types.str;
              default = "/var/lib/homebox/.data/homebox.db?_pragma=busy_timeout=999&_pragma=journal_mode=WAL&_fk=1&_time_format=sqlite";
              description = "Path to the SQLite database file (if using sqlite3).";
            };
            HBOX_OPTIONS_GITHUB_RELEASE_CHECK = mkOption {
              type = types.enum [ "true" "false" ];
              description = "Whether to check GitHub for new releases (true/false).";
              default = "false";
            };
          };
        };
        description = ''
          The homebox configuration as Environment variables. For definitions and available options see the upstream
          [documentation](https://homebox.software/en/configure/#configure-homebox).
        '';
      };
    database = {
      createLocally = mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Configure local PostgreSQL database server for Homebox.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    warnings = mkIf (cfg.settings ? HBOX_STORAGE_DATA) [
      "`services.homebox.settings.HBOX_STORAGE_DATA` has been deprecated. Please use `services.homebox.settings.HBOX_STORAGE_CONN_STRING` and `services.homebox.settings.HBOX_STORAGE_PREFIX_PATH`instead."
    ];
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
    };
    users.groups.${cfg.group} = { };
    services.postgresql = lib.mkIf cfg.database.createLocally {
      enable = true;
      ensureDatabases = [ "homebox" ];
      ensureUsers = [
        {
          name = "homebox";
          ensureDBOwnership = true;
        }
      ];
    };

    systemd =
      {
        services.homebox = {
          requires = lib.optional cfg.database.createLocally "postgresql.target";
          after = lib.optional cfg.database.createLocally "postgresql.target";
          environment =
            let
              baseEnv = lib.filterAttrs (_: v: v != null) cfg.settings;
              dbEnv = lib.optionalAttrs cfg.database.createLocally {
                HBOX_DATABASE_DRIVER = "postgres";
                HBOX_DATABASE_HOST = "/run/postgresql";
                HBOX_DATABASE_USERNAME = "homebox";
                HBOX_DATABASE_DATABASE = "homebox";
                HBOX_DATABASE_PORT = toString config.services.postgresql.settings.port;
              };
            in baseEnv // dbEnv;
          serviceConfig = {
            User = cfg.user;
            Group = cfg.group;
            ExecStart = lib.getExe cfg.package;
            LimitNOFILE = "1048576";
            PrivateTmp = true;
            PrivateDevices = true;
            Restart = "always";
            StateDirectory = "homebox";

            # Hardening
            CapabilityBoundingSet = "";
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            PrivateUsers = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHome = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectProc = "invisible";
            ProcSubset = "pid";
            ProtectSystem = "strict";
            RestrictAddressFamilies = [
              "AF_UNIX"
              "AF_INET"
              "AF_INET6"
              "AF_NETLINK"
            ];
            RestrictNamespaces = true;
            RestrictRealtime = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = [
              "@system-service"
              "@pkey"
            ];
            RestrictSUIDSGID = true;
            PrivateMounts = true;
            UMask = "0077";
          };
          wantedBy = [ "multi-user.target" ];
        };
      };
  };
  meta.maintainers = with lib.maintainers; [
    patrickdag
    swarsel
  ];
}
