{ config, pkgs, lib, tailscaleAuthKey ? null, ... }:

{
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";
  services.openssh.passwordAuthentication = true;

  services.tailscale.enable = true;

  systemd.services.tailscale-autoconnect = lib.mkIf (tailscaleAuthKey != null) {
    description = "Automatically connect to Tailscale";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.tailscale}/bin/tailscale up --authkey ${tailscaleAuthKey}";
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.variables.EDITOR = "nvim";
  environment.systemPackages = with pkgs; [ git neovim tailscale ];

  networking.hostName = "nixos-${config.networking.hostId}";
  users.users.root.initialPassword = "nixos";
}
