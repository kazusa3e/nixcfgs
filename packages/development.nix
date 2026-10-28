{ pkgs }:

with pkgs;
[
  # Build systems and data formats.
  cmake
  ninja
  meson
  protobuf

  # C and C++.
  llvmPackages.clang
  llvmPackages.clang-tools
  cmake-language-server
  cmake-format

  # Rust.
  rustc
  cargo
  rust-analyzer
  rustfmt
  clippy

  # Go.
  go
  gopls

  # Python.
  ty

  # Lua.
  lua-language-server
  stylua

  # Nix.
  nixd
  nixfmt

  # Shell.
  bash-language-server

  # Configuration languages.
  taplo
  yaml-language-server
]
