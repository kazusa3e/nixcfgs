{ pkgs, unstable }:

{
  system =
    with pkgs;
    [
      # tmux 3.7+ fixes truncated OSC 4 replies leaking into input (upstream #4749).
      unstable.tmux
    ]
    ++ [
      # Basic utilities.
      file
      wget
      tree
      curl
      git
      vim
      gnumake
      direnv
      htop
      pstree
      sysstat
      perf
    ];

  user =
    with pkgs;
    [
      # Shell and navigation.
      starship
      zoxide
      fd
      ripgrep
      fzf
      eza
      bat
      yazi
      jq
      stow
      lazygit
      gh
      tldr
    ]
    ++ [
      # Runtimes and build tools.
      python3
      nodejs
      tree-sitter
    ]
    ++ [
      # Container tools.
      podman-compose
    ]
    ++ [
      # Editors.
      neovim
      helix
    ]
    ++ [
      # Language servers and formatters.
      nixd
      nixfmt
      taplo
      cmake
      clang-tools
      gopls
      rust-analyzer
      bash-language-server
      cmake-language-server
      ty
    ]
    ++ [
      # AI tools.
      unstable.pi-coding-agent
      lynx
      unstable.codex
      unstable.opencode
    ];
}
