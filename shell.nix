let
  pkgs = import <nixpkgs> { };
in
pkgs.mkShell {

  name = "nixcfgs-shell";

  packages = with pkgs; [
    nil
    nixfmt
  ];
}
