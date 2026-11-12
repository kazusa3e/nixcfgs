{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-pin-codex.url = "github:NixOS/nixpkgs/f9a75f41be3a74eab55d3a7679d34ad6cc0da977";
  };

  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;
      hosts = import ./hosts;
      pinInputs = lib.filterAttrs (name: _: lib.hasPrefix "nixpkgs-pin-" name) inputs;
      mkHost =
        host:
        let
          inherit (host) system;
          pkgs = import inputs.${host.packageSources.stable} { inherit system; };
          latest =
            if host.packageSources.latest == null then
              pkgs
            else
              import inputs.${host.packageSources.latest} { inherit system; };
          packagePins = lib.mapAttrs' (
            name: input:
            let
              packageName = lib.removePrefix "nixpkgs-pin-" name;
              pinnedPkgs = import input { inherit system; };
            in
            lib.nameValuePair packageName pinnedPkgs.${packageName}
          ) pinInputs;
          extraPackages = (host.extraPackages or (_: [ ])) { inherit pkgs latest; };
          packages = import ./packages {
            inherit
              pkgs
              latest
              extraPackages
              packagePins
              ;
            inherit (host) profiles;
            excludePackages = host.excludePackages or [ ];
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
              "/share/nix-direnv"
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
