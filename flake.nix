{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];

      perSystem = { pkgs, lib, ... }: {
        # Base DigitalOcean image
        packages.doImage =
          (pkgs.nixos
            (import ./modules/doImage.nix { inherit inputs; })
          ).digitalOceanImage;

        apps = {
          # Deployer (for use in `nix run`)
          default.program = lib.getExe pkgs.colmena;
        };

        # Run `nix fmt` to format the Nix files.
        formatter = pkgs.nixpkgs-fmt;
      };

      flake = {
        colmena = {
          meta = {
            nixpkgs = import inputs.nixpkgs {
              system = "x86_64-linux";
              overlays = [ ];
            };
            specialArgs = { inherit inputs; };
          };
          fpindia-chat = { pkgs, ... }: {
            deployment = {
              targetHost = "165.22.214.173"; # DigitalOcean droplet IP
              targetUser = "admin";
            };
            imports = [
              ./modules/doImage.nix
              ./hosts/fpindia-chat
            ];
          };
        };
      };
    };
}
