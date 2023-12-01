# fpindia-chat

WIP: Matrix server (NixOS) for FPIndia

## Setup

### DigitalOcean image

```sh
nix build .#doImage
ls -l result/nixos.qcow2.gz
```

Upload this in DigitalOcean, [`Images -> Custom Images`](https://cloud.digitalocean.com/images/custom_images).

Then create a droplet using this image.

### Secrets

- Create a [shared secret for synapse](https://nixos.org/manual/nixos/stable/index.html#module-services-matrix-register-users) and store it in the appropriate 1Password vault (see `matrix.nix`)

### [Colmena](https://github.com/zhaofengli/colmena) deployment

To build the configuration,

```
nix run . build
```

To deploy the configuration,

```sh
# From Linux
nix run . apply
# NOTE: If you are on macOS, run instead:
# cf. https://colmena.cli.rs/unstable/features/remote-builds.html
nix run . apply -- --build-on-target
```

To SSH to the machine,

```
nix run .#ssh
```

## Hosts

### [`fpindia-chat`](./hosts/fpindia-chat/)

Runs the Matrix server.
