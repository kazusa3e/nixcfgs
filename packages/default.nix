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
      strace
      iotop
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
      sshpass
      entr
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
      # Development tools.
      nixd
      nixfmt
      taplo
      cmake
      clang-tools
      gopls
      rust-analyzer
      bash-language-server
      cmake-language-server
      cmake-format
      ty
      lua-language-server
      stylua
      yaml-language-server
    ]
    ++ [
      # AI tools.
      unstable.pi-coding-agent
      lynx
      unstable.codex
      unstable.opencode
    ];
}
