{
  pkgs,
  latest ? pkgs,
  profiles ? [ "base" ],
  excludePackages ? [ ],
  extraPackages ? [ ],
  packagePins ? { },
}:

let
  inherit (pkgs) lib;

  groups = {
    base = import ./base.nix { inherit pkgs latest; };
    development = import ./development.nix { inherit pkgs latest; };
    ai = import ./ai.nix { inherit pkgs latest; };
  };

  selectedPackages = lib.concatMap (profile: groups.${profile}) profiles;
  # Exclude profile packages by version-independent name; explicit extras remain untouched.
  filteredPackages = lib.filter (
    package: !(builtins.elem (lib.getName package) excludePackages)
  ) selectedPackages;
in
builtins.map (package: packagePins.${lib.getName package} or package) (
  filteredPackages ++ extraPackages
)
