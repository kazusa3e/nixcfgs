{ pkgs }:

with pkgs;
[
  # Basic utilities.
  vim
  file
  curl
  wget
  gnumake
  htop
  git
  tree
  direnv
  pstree
  sshpass
  entr
  fd
  ripgrep
  eza
  bat
  delta
  tldr
  starship
  zoxide
  fzf
  yazi
  jq
  stow
  lazygit
  gh

  # Runtimes and containers.
  python3
  nodejs
  podman-compose

  # Shell integration.
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting

  # Editors.
  neovim
  helix
]
