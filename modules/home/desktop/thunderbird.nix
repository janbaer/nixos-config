{ config, lib, pkgs, ... }:
with lib;
let cfg = config.modules.desktop.thunderbird;
in {
  options.modules.desktop.thunderbird.enable =
    mkEnableOption "Install Thunderbird Mail client";

  config = mkIf cfg.enable {
    programs.thunderbird = {
      enable = true;
      profiles."jan" = { isDefault = true; };
    };

    accounts = {
      email.accounts.mailbox-org = {
        address = "jan.baer@mailbox.org";
        realName = "Jan Baer";
        userName = "jan.baer@mailbox.org";
        # passwordCommand = "gopass show mailbox.org/thunderbird";
        primary = true;

        imap = {
          host = "imap.mailbox.org";
          port = 993;
          tls.enable = true;
        };
        smtp = {
          host = "smtp.mailbox.org";
          port = 587;
          tls.enable = true;
        };

        # Enable this account for Thunderbird
        thunderbird = {
          enable = true;
          profiles = ["jan"];
        };
      };
      calendar.accounts.mailbox-org = {
        remote = {
          type = "caldav";
          url = "https://dav.mailbox.org/caldav";
          userName = "9509585@9509585";
          # passwordCommand = "gopass show mailbox.org/caldav";
        };
      };
      contact.accounts.mailbox-org = {
        remote = {
          type = "carddav";
          url = "https://dav.mailbox.org/carddav";
          userName = "9509585@9509585";
          # passwordCommand = "gopass show mailbox.org/carddav";
        };
      };
    };
  };
}

