# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    opencode = inputs.opencode.packages.${prev.system}.opencode;
    openldap = prev.openldap.overrideAttrs {doCheck = false;};
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  kiru = final: _prev: {
    kiru.kiru = let
      gstPlugins = with final.gst_all_1; [
        gstreamer
        gst-plugins-base
        gst-plugins-good
        gst-plugins-bad
        gst-plugins-ugly
        gst-libav
        gst-plugins-rs
      ];
    in
      inputs.kiru.packages.${final.system}.kiru.overrideAttrs (_oldAttrs: rec {
        version = "0.6.0";
        src = final.fetchurl {
          url = "https://releases.kiru.app/releases/linux/Kiru-${version}-linux-x86_64.tar.gz";
          hash = "sha256-goimd41sms5PA/W5HpZnju7e16OKSwZ138SIICWFIao=";
        };
        buildInputs = final.lib.subtractLists gstPlugins (_oldAttrs.buildInputs or []);
        installPhase = ''
          runHook preInstall

          mkdir -p "$out"
          cp -R bin lib share "$out/"

          wrapProgram "$out/bin/kiru" \
            --prefix PATH : ${
            final.lib.makeBinPath [
              final.ffmpeg
              final.xdg-utils
              final.zenity
            ]
          } \
          --prefix LD_LIBRARY_PATH : "${
            final.lib.makeLibraryPath [
              final.libdrm
              final.libva
            ]
          }"

          runHook postInstall
        '';
      });
  };
}
