{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "recording-display";
      runtimeInputs = [pkgs.hyprland pkgs.jq];
      text = ''
        action="''${1:-on}"
        output=recording

        case "$action" in
          on)
            # Mirrored monitors may not be in the active monitor list.
            monitors=$(hyprctl -j monitors all)
            physical="''${2:-$(jq -r '
              [.[] | select(.name != "recording" and (.name | startswith("HEADLESS-") | not))]
              | sort_by(.focused | not) | .[0].name // empty
            ' <<< "$monitors")}"
            if [[ -z "$physical" ]] || ! jq -e --arg name "$physical" \
              'any(.[]; .name == $name and .name != "recording")' <<< "$monitors" >/dev/null; then
              echo "No physical monitor found. Usage: recording-display on [monitor-name]" >&2
              exit 1
            fi

            if ! jq -e --arg name "$output" 'any(.[]; .name == $name)' <<< "$monitors" >/dev/null; then
              hyprctl output create headless "$output"
            fi
            hyprctl keyword monitor "$output,5120x2880@60,auto,2"
            hyprctl keyword monitor "$physical,preferred,auto,1,mirror,$output"
            hyprctl dispatch focusmonitor "$output"
            echo "Recording display ready: 5120x2880 at 2x, mirrored to $physical."
            echo "Select '$output' in your recorder's screen picker."
            ;;
          off)
            # Reload the configured monitor rules before removing the mirror source.
            hyprctl reload
            if hyprctl -j monitors all | jq -e --arg name "$output" 'any(.[]; .name == $name)' >/dev/null; then
              hyprctl output remove "$output"
            fi
            ;;
          *)
            echo "Usage: recording-display {on [monitor-name]|off}" >&2
            exit 1
            ;;
        esac
      '';
    })
  ];
}
