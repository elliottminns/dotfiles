import os
from pathlib import Path
import re
import subprocess
import sys


STATE = Path("/var/lib/framework-fan-rgb/color")


def color_hex(value):
    if value.lower() == "off":
        return "#000000"
    if re.fullmatch(r"#?[0-9a-fA-F]{6}", value):
        return "#" + value.lstrip("#").lower()
    rgb = re.fullmatch(r"rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)", value)
    if rgb and all(0 <= int(part) <= 255 for part in rgb.groups()):
        return "#" + "".join(f"{int(part):02x}" for part in rgb.groups())
    raise ValueError("Use a six-digit color such as #a855f7, or 'off'.")


def main():
    args = sys.argv[1:]
    if args in (["--help"], ["-h"]):
        print("Usage: fan-rgb [#RRGGBB | off]\nWithout arguments, opens the fan color picker.")
        return
    if args == ["--restore"]:
        if not STATE.exists():
            return
        color = color_hex(STATE.read_text().strip())
    elif len(args) == 1:
        color = color_hex(args[0])
    elif not args:
        choice = subprocess.run(
            [ZENITY, "--list", "--title=Fan RGB", "--column=Lighting",
             "Choose color", "Turn off", "--height=240", "--width=320"],
            text=True, capture_output=True,
        )
        if choice.returncode:
            return
        if choice.stdout.strip() == "Turn off":
            color = "#000000"
        else:
            initial = STATE.read_text().strip() if STATE.exists() else "#a855f7"
            picked = subprocess.run(
                [ZENITY, "--color-selection", "--show-palette", "--title=Fan RGB",
                 f"--color={initial}"], text=True, capture_output=True,
            )
            if picked.returncode:
                return
            color = color_hex(picked.stdout.strip())
    else:
        raise ValueError("Usage: fan-rgb [#RRGGBB | off]")

    if os.geteuid() != 0:
        subprocess.run(
            ["/run/wrappers/bin/sudo", "-n", os.path.realpath(__file__), color],
            check=True,
        )
        return

    subprocess.run(
        [FRAMEWORK_TOOL, "--driver", "cros-ec", "--rgbkbd", "0"]
        + ["0x" + color[1:]] * 8,
        check=True,
    )
    STATE.parent.mkdir(mode=0o755, parents=True, exist_ok=True)
    STATE.write_text(color + "\n")
    STATE.chmod(0o644)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"Fan RGB: {error}", file=sys.stderr)
        sys.exit(1)
