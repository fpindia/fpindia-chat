{ pkgs, ... }:

{
  # Harden.
  services.openssh = {
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
    allowSFTP = false;
  };
  security.auditd.enable = true;
  security.audit.enable = true;
  networking.firewall.enable = true;

  environment.systemPackages = with pkgs; [
    htop
    ncdu
  ];
}
