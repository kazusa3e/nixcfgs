{
  pkgs,
  latest ? null,
  profiles ? [ "base" ],
  extraPackages ? [ ],
}:

let
  inherit (pkgs) lib;

  groups = {
    base = import ./base.nix { inherit pkgs; };
    development = import ./development.nix { inherit pkgs; };
  };

  selectedPackages = lib.concatMap (profile: groups.${profile}) profiles;

  latestPackages = lib.optionals (latest != null) [
    latest.tmux
    latest.pi-coding-agent
    latest.codex
    latest.opencode
  ];

  platformPackages =
    if pkgs.stdenv.isLinux then
      import ./platform/linux.nix { inherit pkgs; }
    else if pkgs.stdenv.isDarwin then
      import ./platform/darwin.nix { inherit pkgs; }
    else
      [ ];
in
selectedPackages ++ latestPackages ++ platformPackages ++ extraPackages
