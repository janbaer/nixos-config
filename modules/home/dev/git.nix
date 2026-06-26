{ config, lib, pkgs, ... }: {
  programs.git = {
    enable = true;
    settings = {
      alias = {
        aliases = "!git config --get-regexp 'alias.*' | colrm 1 6 | sed 's/[ ]/ = /';";
        b = "branch";
        co = "checkout";
        cp = "cherry-pick -xn";
        fp = "!sh -c \"git fetch --prune && git pull\" -";
        nfb = "!sh -c \"git checkout -b feature/$1\" -";
        unstage = "reset head --";
        undo = "checkout --";
        undolastcommit = "reset --hard HEAD~1";
        undounstaged = "!sh -c 'git checkout -- .; git clean -df;'";
        undoall = "reset --hard";
      };
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = true;
      };
      user = {
        email = "jan@janbaer.de";
        name = "Jan Baer";
      };
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
        {
          key = "<f2>";
          context = "files";
          command = "claude -p \"/commit -y\" --allowed-tools \"Bash(git *)\"";
          description = "Commit with Claude";
        }
        {
          key = "<f3>";
          context = "files";
          prompts = [
            {
              type = "input";
              title = "Enter Jira-Ticket";
              key = "JiraTicket";
              initialValue = "VERBU-9318";
            }
          ];
          command = "claude -p \"/gitlab-commit {{.Form.JiraTicket}} -y\" --allowed-tools \"Bash(git *)\"";
          description = "Commit for Jira-Ticket with Claude";
        }
      ]
      ++ lib.optionals config.modules.dev.hunk.enable [
        {
          key = "H";
          context = "files";
          command = "hunk diff HEAD";
          output = "terminal";
          description = "Review all uncommitted changes in hunk";
        }
        {
          key = "H";
          context = "commits";
          command = "hunk show {{.SelectedLocalCommit.Hash}}";
          output = "terminal";
          description = "Review the selected commit in hunk";
        }
        {
          key = "H";
          context = "localBranches";
          command = "hunk diff main...{{.SelectedLocalBranch.Name}}";
          output = "terminal";
          description = "Review branch vs main in hunk";
        }
      ];
    };
  };

  home.shellAliases = {
    g = "git";
    gfp = "git fetch --prune && git pull";
    gcor = "git checkout $(git branch -r --color=never | grep -vE \"$(git branch --color=never | sed ':a;N;$!ba;s/\n/|/g' | sed 's/ //g')\" | sed 's|origin/||g' | sort | fzf)";
    gco = "git checkout $(git branch --color=never | sort | fzf )";
  };
}
