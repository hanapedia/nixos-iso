{
  description = "Custom NixOS Installation ISO with Tailscale and SSH";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        isoConfig = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            tailscaleAuthKey = builtins.getEnv "TAILSCALE_AUTH_KEY";
          };
          modules = [
            "${nixpkgs.outPath}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            ./iso.nix
          ];
        };
      in {
        packages.default = isoConfig.config.system.build.isoImage;
        nixosConfigurations.customIso = isoConfig;
      });
}
