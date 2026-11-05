{
  pkgs,
  latest ? pkgs,
}:

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
  nix-direnv
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
  latest.tmux

  # Runtimes and containers.
  nodejs
  python3
  podman-compose

  # Shell integration.
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting

  # Editors.
  neovim
  helix
]

++ lib.optionals stdenv.isLinux [
  # Linux diagnostics.
  sysstat
  perf
  strace
  iotop
]
