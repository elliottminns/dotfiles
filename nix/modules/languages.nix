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
    rust-analyzer
    rustup
    taplo
    tree-sitter
    valgrind
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
