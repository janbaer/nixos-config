{pkgs, ...}: {
  programs.git = {
    enable = true;
    settings = {
      init = {
        defaultBranch = "main";
      };
      aliases = {
        aliases = "!git config --get-regexp 'alias.*' | colrm 1 6 | sed 's/[ ]/ = /';";
        cp = "cherry-pick -xn";
        co = "!sh -c \"git checkout $(git branch --color=never | sort | fzf)\" -";
        fp = "!sh -c \"git fetch --prune && git pull\" -";
        nfb = "!sh -c \"git checkout -b feature/$1\" -";
        unstage = "reset head --";
        undo = "checkout --";
        undolastcommit = "reset --hard HEAD~1";
        undounstaged = "!sh -c 'git checkout -- .; git clean -df;'";
        undoall = "reset --hard";
      };
      user = {
        email = "jan@janbaer.de";
        name = "Jan Baer";
      };
      pull.rebase = true;
    };
    includes = [
      {
        condition = "gitdir:~/Projects/check24/";
        path = "~/.gitconfig_check24";
      }
    ];
  };

  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        authorColors = {
          "Jan Baer" = "green";
        };
      };
      customCommands = [
        {
          key = "n";
          context = "localBranches";
          prompts = [
            {
              type = "input";
              title = "What is the new feature branch name?";
              key = "BranchName";
              initialValue = "";
            }
          ];
          command = "git checkout -b feature/{{.Form.BranchName}}";
          loadingText = "Creating feature branch";
        }
        {
          key = "<c-p>";
          context = "localBranches";
          command = "git push --no-verify --force-with-lease";
          loadingText = "Git pushing without verifying...";
        }
        {
          key = "<c-t>";
          context = "localBranches";
          command = "git push --tags";
        }
      ];
    };
  };

  home.shellAliases = {
    g = "git";
    gfp = "git fetch --prune && git pull";
    gcor = "git branch -r --color=never | grep -vE \"$(git b --color=never | sed ':a;N;$!ba;s/\n/|/g' | sed 's/ //g')\" | sed 's/origin\///g' | git checkout $(echo $REMOTE_BRANCHES | sort | fzf)";
    gco = "git checkout $(git branch --color=never | sort | fzf )";
  };
}
