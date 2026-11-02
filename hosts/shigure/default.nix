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
  extraPackages = { pkgs, ... }: [
    pkgs.mosh
  ];
}
