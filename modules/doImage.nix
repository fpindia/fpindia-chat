# DigitalOcean custom image for NixOS
#
# Ready to be deployed with SSH access for the user `admin` (with sudo access).

{ inputs, ... }:
let
  adminKeys = [
    # Srid's public key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHQRxPoqlThDrkR58pKnJgmeWPY9/wleReRbZ2MOZRyd"
  ];
in
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
  ];
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "@wheel" ];
  };
  services.openssh.enable = true;
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = adminKeys;
  };
  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "23.11";
}
