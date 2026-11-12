{
  system = "x86_64-darwin";
  packageSources = {
    stable = "nixpkgs-darwin";
    latest = null;
  };
  profiles = [
    "base"
  ];
  # tmux is managed outside Nix on this host.
  excludePackages = [ "tmux" ];
  extraPackages = { pkgs, ... }: [
    pkgs.mosh
  ];
}
