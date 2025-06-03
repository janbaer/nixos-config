{ config, lib, pkgs, ... }:
with lib;
let 
  cfg = config.modules.printing;
  printer = "Samsung_M2020_Series";
  printerIPAddress = "192.168.20.91";
in {
  options.modules.printing.enable =
    mkEnableOption "Configuration for printing with my Samsung printer";

  config = mkIf cfg.enable {
    # https://wiki.nixos.org/wiki/Printing
    services.printing = {
      enable = true;
      drivers = [
        pkgs.samsung-unified-linux-driver
        (pkgs.writeTextDir "share/cups/model/${printer}.ppd" (builtins.readFile ./files/${printer}.ppd))
      ];
    };

    hardware.printers = {
      ensurePrinters = [{
        name = printer;
        location = "Office-Jan";
        deviceUri = "socket://${printerIPAddress}";
        model = "Samsung_M2020_Series.ppd";
        ppdOptions = { PageSize = "A4"; };
      }];
      ensureDefaultPrinter = printer;
    };
  };
}

