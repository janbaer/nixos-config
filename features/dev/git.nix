{pkgs, ...}: {
  programs.git = {
    enable = true;
    userName = "Jan Baer";
    userEmail = "jan@janbaer.de";
  };
  programs.lazygit = {
    enable = true;
  };
}
