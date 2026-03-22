{ pkgs, ... }: {
  home.packages = [ pkgs.fastfetch ];

  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "type": "builtin",
        "source": "apple",
        "padding": {
          "right": 2
        }
      },
      "display": {
        "separator": "  "
      },
      "modules": [
        {
          "type": "title",
          "color": {
            "user": "green",
            "at": "white",
            "host": "cyan"
          }
        },
        {
          "type": "os",
          "key": "os"
        },
        {
          "type": "host",
          "key": "host"
        },
        {
          "type": "kernel",
          "key": "kernel"
        },
        {
          "type": "uptime",
          "key": "uptime"
        },
        {
          "type": "packages",
          "key": "packages"
        },
        {
          "type": "shell",
          "key": "shell"
        },
        {
          "type": "terminal",
          "key": "terminal"
        },
        {
          "type": "cpu",
          "key": "cpu"
        },
        {
          "type": "memory",
          "key": "memory"
        },
        {
          "type": "disk",
          "key": "disk /"
        },
        {
          "type": "break"
        },
        {
          "type": "colors"
        }
      ]
    }
  '';
}
