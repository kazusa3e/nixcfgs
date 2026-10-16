{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs: {
    packages.x86_64-linux =
      let
        pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
        unstable = import inputs.nixpkgs-unstable { system = "x86_64-linux"; };
        packages = import ./packages { inherit pkgs unstable; };
        tools = pkgs.buildEnv {
          name = "nixcfgs-tools";
          paths = packages.system ++ packages.user;
          pathsToLink = [
            "/bin"
            "/share/man"
            "/share/bash-completion"
            "/share/zsh"
            "/share/fish"
          ];
          extraOutputsToInstall = [ "man" ];
          ignoreCollisions = false;
        };
      in
      {
        inherit tools;
        default = tools;
      };

    nixosConfigurations.arashi = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [ ./configuration.nix ];
    };
  };
}
