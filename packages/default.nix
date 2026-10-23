{
  pkgs,
  unstable,
  lib ? pkgs.lib,
}:

with pkgs;
[
  # === Basic utilities. ===
  vim
  file
  curl
  wget
  gnumake
  htop
  git
  tree
  # tmux 3.7+ fixes truncated OSC 4 replies leaking into input (upstream #4749).
  unstable.tmux
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

  # === Shell integration. ===
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting

  # === Runtimes tools. ===
  python3
  nodejs

  # === Container tools. ===
  podman-compose

  # === Editors. ===
  neovim
  helix

  # === Development tools. ===
  cmake
  ninja
  meson
  protobuf
  llvmPackages.clang
  llvmPackages.clang-tools
  rustc
  cargo
  rust-analyzer
  rustfmt
  clippy
  go
  gopls
  ty
  lua-language-server
  stylua
  nixd
  nixfmt
  bash-language-server
  cmake-language-server
  cmake-format
  taplo
  yaml-language-server

  # === AI tools. ===
  unstable.pi-coding-agent
  unstable.codex
  unstable.opencode
]

++ lib.optionals pkgs.stdenv.isLinux [
  sysstat
  perf
  strace
  iotop
]
