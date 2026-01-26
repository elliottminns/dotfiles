{pkgs, ...}: {
  enable = true;

  interactiveShellInit = ''
    set fish_greeting # Disable greeting

    # GPG
    set -gx GPG_TTY (tty)

    # SSH via GPG agent
    set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    gpgconf --launch gpg-agent

    # Editor
    set -gx EDITOR nvim

    # PATH
    set -gx BUN_INSTALL $HOME/.bun
    fish_add_path $HOME/go/bin $BUN_INSTALL/bin
  '';

  shellInitLast = ''
    enable_transience
  '';

  shellAbbrs = {
    vim = "nvim";
    k = "kubectl";
    kx = "kubectx";
    kns = "kubens";
    g = "git";
    gs = "git status";
    gd = "git diff";
    gc = "git commit";
    gp = "git push";
    gl = "git pull";
  };

  shellAliases = {
    ls = "eza";
    ll = "eza -l";
    la = "eza -la";
    tree = "eza --tree";
    r2 = "aws --profile r2 --endpoint-url https://03af1b41c1aa6fe21d9b3a645dca423e.r2.cloudflarestorage.com";
  };

  plugins = [
    {
      name = "autopair";
      src = pkgs.fishPlugins.autopair.src;
    }
    {
      name = "done";
      src = pkgs.fishPlugins.done.src;
    }
    {
      name = "fzf-fish";
      src = pkgs.fishPlugins.fzf-fish.src;
    }
  ];
}
