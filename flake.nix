{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;
      hosts = import ./hosts.nix;
      mkHost =
        host:
        let
          inherit (host) system;
          pkgs = import inputs.nixpkgs { inherit system; };
          unstable =
            if host.useUnstable or true then import inputs.nixpkgs-unstable { inherit system; } else pkgs;
          packages =
            (import ./packages { inherit pkgs unstable; })
            ++ (host.extraPackages or (_: [ ])) { inherit pkgs unstable; };
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
        modules = [ ./configuration.nix ];
      };
    };
}
