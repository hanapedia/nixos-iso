{ config, pkgs, lib, tailscaleAuthKey ? null, ... }:

let
  installScript = pkgs.writeShellScript "auto-install-nixos" ''
    set -eux

    if [ -f /mnt/installed.flag ]; then
      echo "System already installed. Skipping auto-install."
      exit 0
    fi

    # Auto-detect first non-USB disk
    DISK=$(lsblk -dno NAME,TYPE,TRAN | awk '$2 == "disk" && $3 != "usb" { print "/dev/" $1; exit }')

    if [ -z "$DISK" ]; then
      echo "No suitable internal disk found."
      exit 1
    fi

    if mount | grep -q "$DISK"; then
      echo "Selected disk $DISK appears to be in use (possibly the live USB). Aborting."
      exit 1
    fi

    echo "Installing NixOS to $DISK"

    parted --script "$DISK" \
      mklabel gpt \
      mkpart primary ext4 1MiB 100%

    mkfs.ext4 -L nixos "${DISK}1"
    mount "${DISK}1" /mnt

    cp -r /etc/nixos /mnt/etc/

    nixos-install --flake /etc/nixos#default --no-root-password

    touch /mnt/installed.flag
    reboot
  '';
in {
  imports = [];

  # Base tools
  environment.systemPackages = with pkgs; [ git neovim curl parted util-linux ];

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Hostname is generic
  networking.hostName = "nixos";

  # SSH and Tailscale
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";
  services.openssh.passwordAuthentication = true;

  services.tailscale.enable = true;

  systemd.services.tailscale-autoconnect = lib.mkIf (tailscaleAuthKey != null) {
    description = "Auto Tailscale Connect";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "tailscaled.service" ];
    requires = [ "tailscaled.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.tailscale}/bin/tailscale up --authkey ${tailscaleAuthKey}";
    };
  };

  systemd.services.auto-install-nixos = {
    description = "Auto-install NixOS to disk";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = installScript;
    };
  };

  # Add flake to ISO so it can install from it
  environment.etc."nixos".source = ./..;

  users.users.root.initialPassword = "nixos";
  environment.variables.EDITOR = "nvim";
}
