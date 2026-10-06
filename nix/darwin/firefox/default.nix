{...}: let
  # amaterasu's existing profile, confirmed in Firefox/profiles.ini.
  profile = "Library/Application Support/Firefox/Profiles/smlbqcq7.default";
in {
  home.file."${profile}/user.js".source = ./user.js;
  home.file."${profile}/customKeys.json".source = ./customKeys.json;
  home.file."${profile}/chrome/userChrome.css".source = ./userChrome.css;
}
