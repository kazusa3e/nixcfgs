{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # boot.kernelParams = [ "spec_store_bypass_disable=on" ];

  networking.hostName = "arashi";

  time.timeZone = "Asia/Singapore";
  i18n.defaultLocale = "en_US.UTF-8";

  networking.networkmanager.enable = false;
  networking.useNetworkd = true;
  systemd.network.networks = {
    "eth" = {
      matchConfig.Name = "ens*";
      networkConfig.DHCP = "yes";
    };
  };
  services.resolved = {
    enable = true;
    settings.Resolve.LLMNR = "no";
    settings.Resolve.MulticastDNS = "no";
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    openFirewall = true;
  };
  security.sudo.wheelNeedsPassword = false;

  services.tailscale.enable = true;

  # FIX: vscode remote ssh
  # TODO:
  programs.nix-ld.enable = true;

  programs.mosh.enable = true;

  environment.systemPackages = with pkgs; [
    file
    wget
    tree
    curl
    tmux
    htop
    git
    vim
    direnv
    # gnumake
  ];

  environment.variables.EDITOR = "vim";
  environment.variables.VISUAL = "vim";

  virtualisation.podman = {
    enable = true;
    # defaultNetwork.settings.dns_enabled = true;
  };

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  users.users.kazusa = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+3HDmzI4lCdyrTpZpdxwZjVkuplE547xX6/k+tTacG"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      neovim
      helix
      tree-sitter
      starship
      zoxide
      fd
      ripgrep
      fzf
      eza
      stow
      lazygit
      pi-coding-agent
      lynx
      gh
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
