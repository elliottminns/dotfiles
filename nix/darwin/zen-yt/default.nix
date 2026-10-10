{pkgs}: let
  launcher = pkgs.writeScriptBin "zen-yt" (builtins.readFile ../scripts/zen-yt);
in
  pkgs.runCommand "zen-yt" {} ''
    mkdir -p "$out/bin" "$out/Applications/ZenYT.app/Contents/MacOS"
    ln -s ${launcher}/bin/zen-yt "$out/bin/zen-yt"
    ln -s ${launcher}/bin/zen-yt "$out/Applications/ZenYT.app/Contents/MacOS/ZenYT"
    cp ${./Info.plist} "$out/Applications/ZenYT.app/Contents/Info.plist"
  ''
