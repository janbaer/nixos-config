{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.power-management;
in
{
  options.modules.power-management.enable = mkEnableOption "TLP power management for battery-powered hosts";

  config = mkIf cfg.enable {
    services.tlp = {
      enable = true;
      settings = {
        # TUXEDO Control Center owns governor, EPP and the fan curve via its own
        # profiles. TLP reads an empty value as "not configured" and skips the
        # setting entirely, so blanking these four keeps the two daemons off each
        # other's hardware — TLP handles ASPM, runtime PM, USB and radios only.
        CPU_ENERGY_PERF_POLICY_ON_AC = "";
        PLATFORM_PROFILE_ON_AC = "";
        PLATFORM_PROFILE_ON_BAT = "";

        # EPP stays with TCC. tccd polices the value and writes its profile back
        # within a second ("CpuWorker: Incorrect settings, reapplying profile"),
        # so setting it here only produces a reapply on every power change. The
        # battery value belongs in the TCC profile itself.
        CPU_ENERGY_PERF_POLICY_ON_BAT = "";

        # Turbo is the exception: TCC's profile carries noTurbo but tccd never
        # enforces it, and TLP's 0 survives on battery unchallenged.
        CPU_BOOST_ON_BAT = 0;

        # Everything else this host needs is already TLP's default: runtime PM
        # auto, WiFi power saving, audio codec power save, NMI watchdog off and
        # amdgpu ABM level 1 on battery. ASPM is the exception, it ships as
        # `default` (= leave the BIOS setting alone).
        PCIE_ASPM_ON_BAT = "powersave";
      };
    };

    environment.systemPackages = [
      pkgs.powertop
      config.boot.kernelPackages.turbostat
    ];
  };
}
