{
  system = "x86_64-linux";
  packageSources = {
    stable = "nixpkgs";
    latest = "nixpkgs-unstable";
  };
  profiles = [
    "base"
    "development"
    "ai"
  ];
  extraPackages = { pkgs, ... }: [
    pkgs.rclone
  ];
  nixosModule = ./configuration.nix;
}
