# fpindia-chat

WIP: Matrix server (NixOS) for FPIndia

## Flake contents

### DigitalOcean image

```sh
nix build .#doImage
ls -l result/nixos.qcow2.gz
```

Upload this in DigitalOcean, [`Images -> Custom Images`](https://cloud.digitalocean.com/images/custom_images). 

Then create a droplet using this image.

### [Colmena](https://github.com/zhaofengli/colmena) deployment

To build the configuration,

```
nix run . build
```

To deploy the configuration,

```
nix run . deploy
```