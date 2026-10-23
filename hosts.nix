{
  arashi = {
    system = "x86_64-linux";
  };
  koyuki = {
    system = "x86_64-linux";
    extraPackages = { pkgs, ... }: [
      pkgs.tshark
    ];
  };
  shigure = {
    system = "x86_64-darwin";
    # Unstable no longer supports Intel macOS.
    useUnstable = false;
  };
}
