# Firefox on amaterasu

Uses the existing `Profiles/smlbqcq7.default` profile and Nix-installed Firefox.
Home Manager installs `user.js`, `customKeys.json`, and `chrome/userChrome.css`; it does not manage
`profiles.ini` or replace your browsing data.

After applying the Darwin configuration, fully quit and reopen Firefox.

New tabs and new windows open a blank page using Firefox's native Home settings.
Recommended stories, sponsored content, top sites, weather, and feed promotions
are also disabled. Use Command-L to search or enter a URL. The existing startup
session-restore preference is preserved.

- **Control-S**: show/hide the native vertical tabs sidebar and top toolbar together.
  The toolbar sidebar button also changes this shared visibility state.
- **Command-L**: temporarily reveal and focus the address bar when the sidebar is
  hidden. Click the page to hide it again.
- Hovering the top edge or macOS window controls does not change visibility.
- Fullscreen and Customize Toolbar retain Firefox's normal toolbar behavior.

The styling adds rounded tabs, address bar, and a small inset around the page.
The toolbar's navigation row is at least 52 pixels tall. It slides into normal
layout, smoothly making room above both the page and sidebar instead of covering
them. Extra toolbar rows retain their own space. The toolbar stays visible while
focused or while a toolbar popup is open, even if the sidebar is hidden.

Firefox's native “Hide Toolbars” option applies to fullscreen. In normal windows,
this stylesheet follows the sidebar's `[hidden]` state; the Control-S shortcut
still invokes Firefox's native sidebar toggle without a custom script or extension.

The sidebar animates its actual width in both directions. Native sidebar
translation animations are disabled to avoid the page-width snap at the end of
opening. Dragging to resize the sidebar still works, and reduced-motion settings
are respected.
This is custom browser CSS, so Firefox upgrades may require selector adjustments.
The sidebar binding uses Firefox's native `customKeys.json` support; manage
shortcut changes in that file while it is controlled by Home Manager.

To keep the toolbar visible, remove the auto-hide rules from `userChrome.css`
(the `:root[sessionrestored]` block), apply, and restart Firefox.
To revert fully, remove the `./firefox` import from `home.nix`, apply, then reset
the preferences listed in `user.js` in `about:config`; Firefox retains
preferences after `user.js` is removed. Remove `customKeys.json` from the profile
to restore the default sidebar shortcut if it remains after removing the import.

Native sidebar documentation:
https://support.mozilla.org/en-US/kb/use-sidebar-access-tools-and-vertical-tabs
