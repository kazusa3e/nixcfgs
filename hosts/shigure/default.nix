{
  system = "x86_64-darwin";
  packageSources = {
    stable = "nixpkgs-darwin";
    latest = null;
  };
  profiles = [
    "base"
    "development"
  ];
  # These tools are managed outside Nix on this host.
  excludePackages = [
    "tmux"
    "pi-coding-agent"
    "codex"
    "opencode"
  ];
  extraPackages = { pkgs, ... }: [
    pkgs.mosh
  ];
}
