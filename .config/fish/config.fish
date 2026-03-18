set fish_greeting

fish_add_path /opt/homebrew/bin

if status is-interactive
  # Commands to run in interactive sessions can go here
  set -x GPG_TTY (tty)
  set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
  starship init fish | source
  enable_transience
  gpgconf --launch gpg-agent

  zoxide init --cmd cd fish | source
end
