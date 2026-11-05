{
  pkgs,
  latest ? pkgs,
}:

with pkgs;
[
  # C and C++.
  # llvmPackages.clang
  # cmake
  # ninja
  # meson
  llvmPackages.clang-tools
  cmake-language-server
  cmake-format

  # Rust.
  # rustc
  # cargo
  rust-analyzer
  rustfmt
  # clippy

  # Go.
  # go
  gopls
  # gotools

  # Python.
  ty
  black
  isort

  # Lua.
  lua-language-server
  stylua

  # Nix.
  nixd
  nixfmt

  # Shell.
  bash-language-server
  shfmt

  # Web.
  prettier
  prettierd

  # Configuration languages.
  taplo
  yaml-language-server

  # AI coding agents.
  latest.pi-coding-agent
  latest.codex
  latest.opencode
]
