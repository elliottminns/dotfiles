{...}: {
  xdg.configFile."zellij/config.kdl" = {
    source = ./zellij/config.kdl;
    force = true;
  };

  xdg.configFile."zellij/layouts/top-hints-bottom-tabs.kdl".source = ./zellij/layouts/top-hints-bottom-tabs.kdl;
}
