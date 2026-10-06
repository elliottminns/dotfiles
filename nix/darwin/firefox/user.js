// Managed by Home Manager for amaterasu. Applied when Firefox starts.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("sidebar.revamp", true);
user_pref("sidebar.verticalTabs", true);
// The shortcut in customKeys.json toggles the entire sidebar, not just tab labels.
user_pref("sidebar.visibility", "hide-sidebar");
// userChrome.css animates actual sidebar width instead of native translations.
user_pref("sidebar.animation.enabled", false);

// Blank new tabs and new windows, using Firefox's native Home settings.
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.startup.homepage", "about:blank");
// Also opt out of feed content and promotions if Firefox Home is opened directly.
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.showWeather", false);
user_pref("browser.newtabpage.activity-stream.discoverystream.enabled", false);
user_pref("browser.newtabpage.activity-stream.discoverystream.promoCard.visible", false);
