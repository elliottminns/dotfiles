{
  config,
  pkgs,
  lib,
  ...
}: let
  pkgConfigDeps = [
    pkgs.cairo.dev
    pkgs.gdk-pixbuf.dev
    pkgs.glib.dev
    pkgs.gst_all_1.gstreamer.dev
    pkgs.gst_all_1.gst-plugins-bad.dev
    pkgs.gst_all_1.gst-plugins-base.dev
    pkgs.gst_all_1.gst-plugins-good.dev
    pkgs.harfbuzz.dev
    pkgs.gtk3.dev
    pkgs.openssl.dev
    pkgs.pango.dev
  ];
  pkgConfigPath =
    lib.makeSearchPath "lib/pkgconfig" pkgConfigDeps
    + ":"
    + lib.makeSearchPath "share/pkgconfig" pkgConfigDeps;
  exiftoolLibDir = "${pkgs.exiftool}/lib/perl5/site_perl/${pkgs.perl.version}";
  opensslDev = pkgs.openssl.dev;
  opensslLib = pkgs.lib.getLib pkgs.openssl;
in {
  enable = true;
  dotDir = "${config.xdg.configHome}/zsh";
  history.size = 10000;
  history.path = "${config.xdg.dataHome}/zsh/history";
  shellAliases = {
    vim = "nvim";
    ls = "ls --color";
    ctrl-l = "clear";
    C-l = "ctrl-l";
    control-l = "clear";
    clean = "clear";
    drs = "darwin-rebuild switch --flake /Users/elliott/.dotfiles/nix/darwin#amaterasu";
    ff = "fastfetch";
    r2 = "aws --profile r2 --endpoint-url https://03af1b41c1aa6fe21d9b3a645dca423e.r2.cloudflarestorage.com";
    sysinfo = "fastfetch";
  };
  initContent = ''
    ZSH_DISABLE_COMPFIX=true
    export EDITOR=nvim
    if [ -n "$TTY" ]; then
      export GPG_TTY=$(tty)
    else
      export GPG_TTY="$TTY"
    fi

    export BUN_INSTALL=$HOME/.bun
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.cargo/bin:$HOME/go/bin:$BUN_INSTALL/bin:$PATH"
    export EXIFTOOL_LIB_DIR="${exiftoolLibDir}"
    export PKG_CONFIG_PATH="${pkgConfigPath}''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    export OPENSSL_DIR="${opensslDev}"
    export OPENSSL_LIB_DIR="${opensslLib}/lib"
    export OPENSSL_INCLUDE_DIR="${opensslDev}/include"

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

    # Keybindings
    bindkey -e
    typeset -gi __prefix_history_event=0
    typeset -g __prefix_history_query=""
    typeset -g __prefix_history_current=""

    __prefix_history_search() {
      emulate -L zsh

      local direction="$1"
      local prefix start event line
      local -a events

      if [[ "$BUFFER" == "$__prefix_history_current" && -n "$__prefix_history_query" ]]; then
        prefix="$__prefix_history_query"
        start=$__prefix_history_event
      else
        __prefix_history_query="$BUFFER"
        __prefix_history_current="$BUFFER"
        __prefix_history_event=$HISTCMD
        prefix="$BUFFER"
        start=$HISTCMD
      fi

      if [[ "$direction" == "backward" ]]; then
        events=( ''${(Onk)history} )
        for event in $events; do
          (( event < start )) || continue
          line=$history[$event]
          [[ "''${line[1,$#prefix]}" == "$prefix" ]] || continue
          BUFFER="$line"
          CURSOR=$#BUFFER
          __prefix_history_current="$line"
          __prefix_history_event=$event
          return 0
        done
      else
        events=( ''${(onk)history} )
        for event in $events; do
          (( event > start )) || continue
          line=$history[$event]
          [[ "''${line[1,$#prefix]}" == "$prefix" ]] || continue
          BUFFER="$line"
          CURSOR=$#BUFFER
          __prefix_history_current="$line"
          __prefix_history_event=$event
          return 0
        done
      fi

      zle beep
      return 1
    }

    __prefix_history_search_backward() {
      __prefix_history_search backward
    }

    __prefix_history_search_forward() {
      __prefix_history_search forward
    }

    zle -N __prefix_history_search_backward
    zle -N __prefix_history_search_forward
    bindkey '^p' __prefix_history_search_backward
    bindkey '^n' __prefix_history_search_forward
    bindkey '^[w' kill-region

    zle_highlight+=(paste:none)

    setopt appendhistory
    setopt sharehistory
    setopt hist_ignore_space
    setopt hist_ignore_all_dups
    setopt hist_save_no_dups
    setopt hist_ignore_dups
    setopt hist_find_no_dups

    autoload -Uz edit-command-line
    zle -N edit-command-line
    bindkey '^x^e' edit-command-line

    alias -g NE='2>/dev/null'
    alias -g ND='>/dev/null'
    alias -g NUL='>/dev/null 2>1'
    alias -g JQ='| jq'
    alias -g C='| wl-copy'

    dburl() {
      if [[ -z "$1" ]]; then
        echo "Doppler project is missing"
        return 1
      fi
      if [[ -z "$2" ]]; then
        echo "Doppler config is missing"
        return 1
      fi
      export DATABASE_URL=$(doppler run -p "$1" -c "$2" -- bash -c 'echo $DATABASE_URL')
    }

    opendb() {
      if [[ -z "$1" ]]; then
        echo "Doppler project is missing"
        return 1
      fi
      if [[ -z "$2" ]]; then
        echo "Doppler config is missing"
        return 1
      fi
      psql "$(doppler run -p "$1" -c "$2" -- bash -c 'echo $DATABASE_URL')"
    }
  '';
  oh-my-zsh = {
    enable = true;
    plugins = [
      "git"
      "sudo"
      "docker"
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
    #{
    # will source zsh-autosuggestions.plugin.zsh
    #name = "zsh-autosuggestions";
    #src = pkgs.zsh-autosuggestions;
    #file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
    #}
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
    {
      name = "powerlevel10k";
      src = pkgs.zsh-powerlevel10k;
      file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    }
    {
      name = "powerlevel10k-config";
      src = lib.cleanSource ../../.p10k.zsh;
      file = "p10k.zsh";
    }
    {
      name = "fzf-tab";
      src = pkgs.zsh-fzf-tab;
      file = "share/fzf-tab/fzf-tab.plugin.zsh";
    }
  ];
}
