How to install:

nix --extra-experimental-features flakes --extra-experimental-features nix-command run --debug github:numtide/nixos-anywhere --verbose -- --flake .#nixos root@yourhost.com

You will need to maually make these:
```
/root/.ssh/id_rsa
/root/.ssh/id_rsa.pub
/root/.ssh/id_rsa.pem
```
