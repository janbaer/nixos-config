{ config, lib, ... }:
with lib;
let
  cfg = config.modules.zram;
in
{
  options.modules.zram.enable = mkEnableOption "zram swap + systemd-oomd memory-pressure safety net";

  config = mkIf cfg.enable {
    # Compressed RAM-backed swap. Gives the kernel a reclaim buffer instead of
    # jumping straight to the OOM killer when RAM fills — without disk wear.
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
    };

    # With swap present, let systemd-oomd kill the single worst-offending cgroup
    # under sustained memory pressure before the kernel's blunt global OOM killer
    # fires and takes the whole graphical session (compositor included) down.
    systemd.oomd = {
      enable = true;
      enableRootSlice = true;
      enableUserSlices = true;
    };
  };
}
