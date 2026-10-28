{
  system = "x86_64-linux";
  packageSources = {
    stable = "nixpkgs";
    latest = "nixpkgs-unstable";
  };
  profiles = [
    "base"
    "development"
  ];
  nixosModule = ./configuration.nix;
}
