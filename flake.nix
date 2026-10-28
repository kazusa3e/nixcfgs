{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;
      hosts = import ./hosts;
      mkHost =
        host:
        let
          inherit (host) system;
          pkgs = import inputs.${host.packageSources.stable} { inherit system; };
          latest =
            if host.packageSources.latest == null then
              null
            else
              import inputs.${host.packageSources.latest} { inherit system; };
          extraPackages = (host.extraPackages or (_: [ ])) { inherit pkgs latest; };
          packages = import ./packages {
            inherit pkgs latest extraPackages;
            inherit (host) profiles;
          };
        in
        {
          inherit packages;
          tools = pkgs.buildEnv {
            name = "nixcfgs-tools";
            paths = packages;
            pathsToLink = [
              "/bin"
              "/share/man"
              "/share/bash-completion"
              "/share/zsh"
              "/share/zsh-autosuggestions"
              "/share/zsh-syntax-highlighting"
            ];
            extraOutputsToInstall = [ "man" ];
            ignoreCollisions = false;
          };
        };

      arashi = mkHost hosts.arashi;
      koyuki = mkHost hosts.koyuki;
      shigure = mkHost hosts.shigure;
    in
    {
      # Merge entries so hosts can share a platform.
      packages = lib.foldl' lib.recursiveUpdate { } [
        { ${hosts.arashi.system}.arashi = arashi.tools; }
        { ${hosts.koyuki.system}.koyuki = koyuki.tools; }
        { ${hosts.shigure.system}.shigure = shigure.tools; }
      ];

      nixosConfigurations.arashi = lib.nixosSystem {
        system = hosts.arashi.system;
        specialArgs = {
          userPackages = arashi.packages;
        };
        modules = [ hosts.arashi.nixosModule ];
      };
    };
}
