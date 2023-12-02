{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];

      perSystem = { pkgs, lib, ... }:
        let
          mkColmenaApps = { name, config }: rec {
            # Runs `colmena` executable.
            default.program = lib.getExe pkgs.colmena;
            # SSH's to the target host in `config`.
            ssh.program = pkgs.writeShellScriptBin "ssh-${name}"
              ''
                ADDR=''$(${default.program} eval -E '{ nodes, ... }:
                    let cfg = nodes.${name}.config.deployment;
                    in "''${cfg.targetUser}@''${cfg.targetHost}"' | tr -d '"'
                )
                set -x
                ssh $ADDR
              '';
            # Run's `colmena apply`. Enables remote build on macOS.
            deploy.program = pkgs.writeShellScriptBin "deploy-${name}"
              (if pkgs.stdenv.isLinux
              then "${default.program} apply"
              else "${default.program} apply --build-on-target");
          };
        in
        {
          # Base DigitalOcean image
          packages.doImage =
            (pkgs.nixos
              (import ./modules/doImage.nix { inherit inputs; })
            ).digitalOceanImage;

          apps = mkColmenaApps { name = "fpindia-chat"; config = self.server-config; };

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
