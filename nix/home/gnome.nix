{...}: {
  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell/keybindings".show-screenshot-ui = ["<Super><Shift>s"];
      "org/gnome/desktop/interface".color-scheme = "prefer-dark";
      "org/gnome/shell".enabled-extensions = [
        "just-perfection-desktop@just-perfection"
      ];
      "org/gnome/shell/extensions/just-perfection".panel = false;
    };
  };
}
