{pkgs, ...}: {
  enable = true;
  package = pkgs.firefox.override {
    cfg = {
      # Gnome shell native connector
      enableGnomeExtensions = true;
    };
  };

  profiles = {
    default = {
      id = 0;
      name = "default";
      isDefault = true;
      settings = {
        "middlemouse.paste" = false;
      };
    };
  };
}
