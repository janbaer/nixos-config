{ username, ... }: 
{
  age = {
    secrets = {
      "zsh-secrets" = {
        file = ../../secrets/zsh-secrets.age;
        path = "/home/${username}/.config/zsh/.zsh-secrets";
        owner = "${username}";
        mode = "0600";
        symlink = false;
      };
      "id_ed25519" = {
        file = ../../secrets/id_ed25519.age;
        path = "/home/${username}/.ssh/id_ed25519";
        owner = "${username}";
        mode = "0600";
        symlink = false;
      };
      "id_ed25519_jabasoft-ug" = {
        file = ../../secrets/id_ed25519_jabasoft-ug.age;
        path = "/home/${username}/.ssh/id_ed25519_jabasoft-ug";
        owner = "${username}";
        mode = "0600";
        symlink = false;
      };
      atuin = {
        file = ../../secrets/atuin.age;
        path = "../../secrets/atuin.toml";
        owner = "${username}";
        mode = "0600";
      };
      gpg_key = {
        file = ../../secrets/private-gpg-key.age;
        path = "/home/${username}/.gnupg/private-key.gpg";
        owner = "${username}";
        mode = "0600";
      };
    };
  };

  system.activationScripts.script.text = ''
    #!/usr/bin/env bash
    for dir in .config .config/zsh .gnupg; do
      chown -R ${username}: /home/${username}/$dir
      chmod 0700 /home/${username}/$dir
    done
  '';
}
