{ username
, ...
}: {
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
      "id_ed25519_forgejo" = {
        file = ../../secrets/id_ed25519_forgejo.age;
        path = "/home/${username}/.ssh/id_ed25519_forgejo";
        owner = "${username}";
        mode = "0600";
        symlink = false;
      };
    };
  };
}
