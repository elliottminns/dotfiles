{
  config,
  pkgs,
  ...
}: {
  enable = true;
  lfs.enable = true;
  settings.user.name = "Elliott Minns";
  settings.user.email = "elliott.minns@pm.me";
  signing.key = null;
  signing.signByDefault = true;

  settings = {
    pull = {
      rebase = true;
    };
    init = {
      defaultBranch = "main";
    };

    # url = {
    #   "git@github.com:" = {
    #     insteadOf = "https://github.com/";
    #   };
    # };
  };
}
