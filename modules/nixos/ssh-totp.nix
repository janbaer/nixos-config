{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.modules.sshTotp;
in
{
  options.modules.sshTotp.enable = mkEnableOption "TOTP second factor for SSH login (publickey + TOTP)";

  config = mkIf cfg.enable {
    age.secrets.google-authenticator = {
      file = ../../secrets/google-authenticator.age;
      path = "/home/${username}/.google_authenticator";
      owner = username;
      mode = "0600";
    };

    environment.systemPackages = [ pkgs.google-authenticator ];

    # security.pam.services.sshd.googleAuthenticator.enable is NOT used here: NixOS
    # only wires that convenience option in when unixAuth (or systemd-homed) is also
    # true, which it isn't on this key-only setup — the module would silently vanish
    # from the PAM stack. Defining the rule directly sidesteps that gate.
    security.pam.services.sshd = {
      u2f.enable = false; # otherwise a registered Yubikey alone satisfies SSH login, bypassing TOTP
      rules.auth.google_authenticator = {
        # Offset from `deny`'s order rather than a literal number, since built-in
        # order values can shift between nixpkgs releases (see that option's own docs).
        order = config.security.pam.services.sshd.rules.auth.deny.order - 100;
        control = "sufficient"; # must stop the stack on success, or the final `deny` rule always denies afterwards
        modulePath = "${pkgs.google-authenticator}/lib/security/pam_google_authenticator.so";
      };
    };

    services.openssh.settings = {
      KbdInteractiveAuthentication = true;
      AuthenticationMethods = "publickey,keyboard-interactive";
    };
  };
}
