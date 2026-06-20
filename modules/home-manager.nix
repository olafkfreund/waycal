# home-manager module for waycal. Imported as a flake module (NOT the
# home-manager CLI):
#
#   imports = [ inputs.waycal.homeManagerModules.waycal ];
#   programs.waycal = {
#     enable = true;
#     account = "you@example.com";
#     keyringPasswordFile = config.age.secrets."waycal-gog".path;  # holds GOG_KEYRING_PASSWORD=…
#   };
self:
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.waycal;

  tomlFormat = pkgs.formats.toml { };

  defaultPackage =
    self.packages.${pkgs.stdenv.hostPlatform.system}.waycal or null;

  # quickshell comes through the package's passthru so the module doesn't need
  # the flake input directly.
  quickshellPkg = cfg.package.quickshell;
in
{
  options.programs.waycal = {
    enable = lib.mkEnableOption "waycal Google productivity widgets for Quickshell";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression "waycal.packages.\${system}.waycal";
      description = "The waycal package to use.";
    };

    account = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "you@example.com";
      description = ''
        The gog account email to query. Equivalent to setting
        {option}`settings.account`. Leave empty to rely on `$GOG_ACCOUNT`
        or gog's single stored token.
      '';
    };

    keyringPasswordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression ''config.age.secrets."waycal-gog".path'';
      description = ''
        Path to an EnvironmentFile read by the systemd user service. It must
        define at least `GOG_KEYRING_PASSWORD=…` so gog can decrypt its refresh
        token non-interactively, and may also set `GOG_ACCOUNT=…`. This file is
        never copied into the Nix store.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = tomlFormat.type;
        options = {
          account = lib.mkOption {
            type = lib.types.str;
            default = cfg.account;
            defaultText = lib.literalExpression "config.programs.waycal.account";
            description = "gog account email.";
          };
          agenda_days = lib.mkOption {
            type = lib.types.int;
            default = 7;
            description = "How many days ahead the agenda widget shows.";
          };
          mail_query = lib.mkOption {
            type = lib.types.str;
            default = "in:inbox is:unread";
            description = "Gmail search query for the mail widget.";
          };
          task_lists = lib.mkOption {
            type = lib.types.str;
            default = "all";
            description = "'all' or a comma-separated set of task list ids/names.";
          };
          calendars = lib.mkOption {
            type = lib.types.str;
            default = "all";
            description = "'all' or a comma-separated set of calendar ids/names.";
          };
        };
      };
      default = { };
      description = ''
        Written verbatim to {file}`$XDG_CONFIG_HOME/waycal/config.toml` and read
        by `waycal-fetch`. Any extra keys are passed through.
      '';
    };

    systemd = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Run Quickshell as a systemd --user service. This is the recommended
          way to supply {option}`keyringPasswordFile` to gog: the env is
          inherited by every `waycal-fetch`/`gog` the UI spawns.
        '';
      };

      target = lib.mkOption {
        type = lib.types.str;
        default = "graphical-session.target";
        description = "systemd user target the service binds to.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.package != null;
        message = "programs.waycal.package is null; set it to the waycal package for your system.";
      }
      {
        assertion = !cfg.systemd.enable || cfg.keyringPasswordFile != null;
        message = ''
          programs.waycal.systemd.enable is true but keyringPasswordFile is unset.
          gog cannot read its token non-interactively without GOG_KEYRING_PASSWORD.
          Provide a secret file (agenix/sops) or set systemd.enable = false and
          supply the env another way.
        '';
      }
    ];

    home.packages = [ cfg.package quickshellPkg ];

    # The Quickshell config: symlink the package's frontend into place.
    xdg.configFile."quickshell/waycal".source = "${cfg.package}/share/waycal/frontend";

    # Adapter config.
    xdg.configFile."waycal/config.toml".source =
      tomlFormat.generate "waycal-config.toml" cfg.settings;

    systemd.user.services.waycal = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "waycal — Quickshell Google productivity widgets";
        PartOf = [ cfg.systemd.target ];
        After = [ cfg.systemd.target ];
      };
      Service = {
        ExecStart = "${quickshellPkg}/bin/qs -c waycal";
        EnvironmentFile = lib.optional (cfg.keyringPasswordFile != null) (toString cfg.keyringPasswordFile);
        # waycal-fetch (from cfg.package) AND `gog` must both be on PATH for the
        # QML Process calls. gog usually lives in the user/home profile, so those
        # dirs are included explicitly (resolved declaratively, no specifiers).
        Environment = [
          ("PATH=" + lib.concatStringsSep ":" [
            (lib.makeBinPath [ cfg.package quickshellPkg pkgs.coreutils ])
            "${config.home.homeDirectory}/.nix-profile/bin"
            "/etc/profiles/per-user/${config.home.username}/bin"
            "/run/current-system/sw/bin"
          ])
        ];
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ cfg.systemd.target ];
    };

    meta.maintainers = [ ];
  };
}
