{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
with lib;
let
  cfg = config.modules.desktop.hyprland.batteryRefreshRate;
  inherit (import ./../../../../hosts/${hostname}/variables.nix) monitors;

  outputs = map (m: m.output) monitors;

  # TCC can switch the refresh rate per profile, but does it through xrandr,
  # which is a no-op under Hyprland. hyprctl is the only way in on Wayland, and
  # under the Lua config it has to be `eval` with an hl.monitor() call —
  # `hyprctl keyword` refuses to run against a non-legacy parser.
  # The mode is rebuilt from the monitor's live geometry rather than from
  # variables.nix, whose `mode = "preferred"` says nothing about the resolution.
  switcher = pkgs.writeShellScript "hypr-refresh-rate" ''
    apply() {
      # Any mains supply reporting online counts as AC. Only line-power devices
      # carry `online`, batteries do not, so the glob cannot match the wrong one
      # — and it survives the ADP1/ACAD/AC0 naming zoo across vendors.
      if ${pkgs.gnugrep}/bin/grep -qs '^1$' /sys/class/power_supply/*/online; then
        rate=${toString cfg.acRate}
      else
        rate=${toString cfg.batteryRate}
      fi
      for out in ${escapeShellArgs outputs}; do
        call=$(${pkgs.hyprland}/bin/hyprctl -j monitors \
          | ${pkgs.jq}/bin/jq -r --arg o "$out" --arg r "$rate" \
              '.[] | select(.name == $o) | select((.refreshRate | round) != ($r | tonumber))
               | "hl.monitor({ [\"output\"] = \"\($o)\", [\"mode\"] = \"\(.width)x\(.height)@\($r)\", [\"position\"] = \"\(.x)x\(.y)\", [\"scale\"] = \(.scale) })"')
        [ -n "$call" ] && ${pkgs.hyprland}/bin/hyprctl eval "$call"
      done
    }

    apply
    ${pkgs.glib}/bin/gdbus monitor --system \
      --dest org.freedesktop.UPower --object-path /org/freedesktop/UPower \
      | while read -r _; do apply; done
  '';
in
{
  options.modules.desktop.hyprland.batteryRefreshRate = {
    enable = mkEnableOption "Drop the panel refresh rate while running on battery";

    batteryRate = mkOption {
      type = types.ints.positive;
      default = 60;
      description = "Refresh rate in Hz applied while on battery.";
    };

    acRate = mkOption {
      type = types.ints.positive;
      default = 120;
      description = "Refresh rate in Hz applied while on AC.";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.hypr-refresh-rate = {
      Unit = {
        Description = "Switch the panel refresh rate on AC/battery changes";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${switcher}";
        Restart = "on-failure";
        # Hyprland's socket is not up the instant the session target is reached;
        # without a delay a failed start burns through systemd's rate limit.
        RestartSec = "5s";
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };
  };
}
