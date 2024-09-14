{
  config,
  pkgs,
  ...
}: {
  enable = true;
  history.size = 10000;
  history.path = "${config.xdg.dataHome}/zsh/history";
  shellAliases = {
    vim = "nvim";
    ls = "ls --color";
    ctrl-l = "clear";
    C-l = "ctrl-l";
    control-l = "clear";
    clean = "clear";
  };
  initExtra = ''
    export EDITOR=nvim
    if [ -n "$TTY" ]; then
      export GPG_TTY=$(tty)
    else
      export GPG_TTY="$TTY"
    fi

    export BUN_INSTALL=$HOME/.bun
    export PATH="$HOME/go/bin:$BUN_INSTALL/bin:$PATH"

    # SSH_AUTH_SOCK set to GPG to enable using gpgagent as the ssh agent.
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    gpgconf --launch gpg-agent

    bindkey -e

    [[ ! -f ${./p10k.zsh} ]] || source ${./p10k.zsh}

    # disable sort when completing `git checkout`
    zstyle ':completion:*:git-checkout:*' sort false
    # set descriptions format to enable group support
    # NOTE: don't use escape sequences here, fzf-tab will ignore them
    zstyle ':completion:*:descriptions' format '[%d]'
    # set list-colors to enable filename colorizing
    zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
    # force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
    zstyle ':completion:*' menu no
    # preview directory's content with eza when completing cd
    zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
    zstyle ':fzf-tab:complete:ls:*' fzf-preview 'cat $realpath'
    # switch group using `<` and `>`
    zstyle ':fzf-tab:*' switch-group '<' '>'

    bindkey '^[w' kill-region

    zle_highlight+=(paste:none)

    setopt appendhistory
    setopt sharehistory
    setopt hist_ignore_space
    setopt hist_ignore_all_dups
    setopt hist_save_no_dups
    setopt hist_ignore_dups
    setopt hist_find_no_dups
  '';
  oh-my-zsh = {
    enable = true;
    plugins = [
      "git"
      "sudo"
      "golang"
      "kubectl"
      "kubectx"
      "rust"
      "command-not-found"
      "pass"
      "helm"
    ];
  };
  plugins = [
    {
      # will source zsh-autosuggestions.plugin.zsh
      name = "zsh-autosuggestions";
      src = pkgs.zsh-autosuggestions;
      file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
    }
    {
      name = "zsh-completions";
      src = pkgs.zsh-completions;
      file = "share/zsh-completions/zsh-completions.zsh";
    }
    {
      name = "zsh-syntax-highlighting";
      src = pkgs.zsh-syntax-highlighting;
      file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
    }
    # {
    #   name = "powerlevel10k";
    #   src = pkgs.zsh-powerlevel10k;
    #   file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    # }
    {
      name = "fzf-tab";
      src = pkgs.zsh-fzf-tab;
      file = "share/fzf-tab/fzf-tab.plugin.zsh";
    }
  ];
}
