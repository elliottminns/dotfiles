{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    air
    elixir
    gcc
    #    laravel
    htmx-lsp
    go
    gopls
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
