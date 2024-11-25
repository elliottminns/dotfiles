{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    air
    elixir
    gcc
    #    laravel
    htmx-lsp
    unstable.go_1_23
    nodejs
    rustup
    yarn
    gofumpt
    golines
    goimports-reviser
    gnumake
    php
    vscode-langservers-extracted
    unstable.templ
    tailwindcss
    tailwindcss-language-server
  ];
}
