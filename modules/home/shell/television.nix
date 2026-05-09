{ config, lib, pkgs, ... }:
with lib;
let cfg = config.modules.shell.television;
in {
  options.modules.shell.television = {
    enable = mkEnableOption "television fuzzy finder TUI";
    enableK8sAliases = mkEnableOption "kubernetes channel wrappers (tvkp/tvks/tvkd)";
  };

  config = mkIf cfg.enable {
    programs.television = {
      enable = true;
      enableZshIntegration = true;
    };

    home.packages = with pkgs; [
      tealdeer  # Fast Rust client for tldr-pages, backs the `tv tldr` channel
    ];

    # Symlink every *.toml under ./files/televison/cable/ into the user's
    # television cable directory. New files are picked up on the next rebuild
    # without touching this module.
    xdg.configFile = let
      cableDir = ./files/television/cable;
      toEntry = name: {
        name = "television/cable/${name}";
        value.source = cableDir + "/${name}";
      };
    in builtins.listToAttrs (map toEntry
      (filter (hasSuffix ".toml")
        (builtins.attrNames (builtins.readDir cableDir))));

    # Reader pickers: the preview pane is the answer; output is incidental.
    # `tvp` stays an alias because the procs cable ships its own Ctrl-K kill action.
    home.shellAliases = {
      tvm  = "tv man-pages";
      tvtl = "tv tldr";
      tva  = "tv alias";
      tve  = "tv env";
      tvp  = "tv procs";
      tvssh  = "tv ssh-hosts";
    };

    # Actor pickers: a bare alias just prints the selection, so wrap each in a
    # zsh function that consumes the selection and runs the obvious follow-up.
    programs.zsh.initContent = ''
      tvb() {
        local branch
        branch=$(tv git-branch) || return
        [[ -n $branch ]] && git checkout "$branch"
      }

      tvl() {
        local sha
        sha=$(tv git-log) || return
        [[ -n $sha ]] && git show "$sha" | less -R
      }

      tvr() {
        local repo
        repo=$(tv git-repos) || return
        [[ -n $repo ]] && cd "$repo"
      }

      tvd() {
        local file
        file=$(tv git-diff) || return
        [[ -n $file ]] && ''${EDITOR:-vim} "$file"
      }

      tvn() {
        local file
        file=$(tv files) || return
        [[ -n $file ]] && nvim "$file"
      }
    '' + optionalString cfg.enableK8sAliases ''

      tvkp() {
        local pod
        pod=$(tv k8s-pods) || return
        [[ -n $pod ]] && kubectl describe pod "$pod"
      }

      tvks() {
        local svc
        svc=$(tv k8s-services) || return
        [[ -n $svc ]] && kubectl describe service "$svc"
      }

      tvkd() {
        local dep
        dep=$(tv k8s-deployments) || return
        [[ -n $dep ]] && kubectl describe deployment "$dep"
      }
    '';
  };
}
