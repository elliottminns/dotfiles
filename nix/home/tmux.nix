{pkgs, ...}: {
  enable = true;

  aggressiveResize = true;
  baseIndex = 1;
  disableConfirmationPrompt = true;
  keyMode = "vi";
  newSession = true;
  secureSocket = true;
  shell = "${pkgs.zsh}/bin/zsh";
  # NOTE: Keep prefix off of Ctrl+A so Zsh can use Ctrl+A (beginning-of-line).
  shortcut = "Space";
  terminal = "tmux-256color";

  plugins = with pkgs.tmuxPlugins; [
    yank
    sensible
    vim-tmux-navigator
  ];

  extraConfig = ''
    # set-default colorset-option -ga terminal-overrides ",xterm-256color:Tc"
    set -as terminal-features ",xterm-256color:RGB"
    set -as terminal-features ",xterm-ghostty:RGB"
    set -as terminal-features ",tmux-256color:RGB"
    # set-option -sa terminal-overrides ",xterm*:Tc"
    set -g mouse on

    unbind C-b
    set -g prefix C-Space
    bind C-Space send-prefix

    # Vim style pane selection
    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R

    # Start windows and panes at 1, not 0
    set -g base-index 1
    set -g pane-base-index 1
    set-window-option -g pane-base-index 1
    set-option -g renumber-windows on

    # Bind clearing the screen
    bind L send-keys '^L'

    # Use Alt-arrow keys without prefix key to switch panes
    bind -n M-Left select-pane -L
    bind -n M-Right select-pane -R
    bind -n M-Up select-pane -U
    bind -n M-Down select-pane -D

    # Shift arrow to switch windows
    bind -n S-Left  previous-window
    bind -n S-Right next-window

    # Shift Alt vim keys to switch windows
    bind -n M-H previous-window
    bind -n M-L next-window

    # Tokyo Night: a quiet top bar with rounded session and window tabs.
    set -g status-position top
    set -g status-style "bg=#16161e,fg=#a9b1d6"
    set -g status-justify centre
    set -g status-left-length 40
    set -g status-right-length 60
    set -g status-left "#[fg=#bb9af7,bg=#16161e]#[fg=#16161e,bg=#bb9af7,bold] #S #[fg=#bb9af7,bg=#16161e,nobold] "
    set -g status-right "#{?window_zoomed_flag,#[fg=#e0af68] ZOOM  ,}#[fg=#565f89]#{b:pane_current_path} "
    set -g window-status-separator " "
    set -g window-status-format "#[fg=#565f89,bg=#16161e] #I #W "
    set -g window-status-current-format "#[fg=#7aa2f7,bg=#16161e]#[fg=#16161e,bg=#7aa2f7,bold] #I #W #[fg=#7aa2f7,bg=#16161e,nobold]"
    set -g window-status-activity-style "fg=#e0af68"
    set -g window-status-bell-style "fg=#f7768e,bold"

    # Keep split panes legible without drawing attention away from the content.
    set -g pane-border-style "fg=#292e42"
    set -g pane-active-border-style "fg=#7aa2f7"
    set -g pane-border-status "#{?#{>:#{window_panes},1},top,off}"
    set -g pane-border-format "#[fg=#565f89] #P · #{pane_current_command} · #{b:pane_current_path} "
    set -g mode-style "bg=#33467c,fg=#c0caf5"
    set -g message-style "bg=#292e42,fg=#c0caf5"
    set -g message-command-style "bg=#292e42,fg=#7aa2f7"

    # set vi-mode
    set-window-option -g mode-keys vi

    # keybindings
    bind-key -T copy-mode-vi v send-keys -X begin-selection
    bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
    bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

    bind '"' split-window -v -c "#{pane_current_path}"
    bind % split-window -h -c "#{pane_current_path}"
    bind c new-window -c "#{pane_current_path}"
  '';
}
