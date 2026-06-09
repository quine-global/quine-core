# QUINE Core

A fully declarative NixOS server template. Every service, user, certificate, secret, and shell alias is expressed as Nix code — no manual steps, no configuration drift. Deploy to a fresh VPS and get a complete personal server in one command.

In production this configuration runs [blog.quinefoundation.com](https://blog.quinefoundation.com) and related sites.

---

## What you can host

### Static sites (Nix store)

Static files can be embedded directly into the Nix store at build time and served by nginx. The site is immutable and reproducible — no web root to maintain.

```nix
hobbyRoot = pkgs.runCommand "my-static-site" {} ''
  mkdir -p $out
  cp ${./static-site/index.html} $out/index.html
'';
```

See `nixos/nginx.nix` and `nixos/static-site/` for the example.

### PHP sites via Pullomatic

[Pullomatic](https://github.com/philip-peterson/pullomatic) is a lightweight Rust daemon that periodically pulls a git repository to a local directory. nginx's PHP-FPM integration then serves it directly. This is ideal for personal sites or small web apps written in PHP.

- Git repo → `/etc/pullomatic/<name>` → nginx serves it with PHP-FPM
- URL rewrite rules are configured per-site in `nixos/nginx.nix`
- PHP is installed via `environment.systemPackages`

### Static sites via Pullomatic

The same Pullomatic pull mechanism works for pure static content. Point nginx at the checked-out directory with no PHP-FPM block.

See `nixos/nginx.nix` (`quineglobal.com` vhost) for an example.

### Docker / Podman apps via Arion

[Arion](https://github.com/hercules-ci/arion) is a NixOS-native wrapper around Docker Compose that uses Podman as its backend. Each application lives in its own `arion-<name>/` directory with an `arion-compose.nix` file.

Included examples:

| Directory | App | What it is |
|---|---|---|
| `arion/` | **Forgejo** | Self-hosted git forge with SSH and HTTPS |
| `arion-riverside/` | **WordPress + MySQL** | Template for any multi-service web app |
| `arion-pluto/` | **Pluto** | Julia reactive notebook server |
| `arion-paperless/` | **Paperless-NGX** | Document management with OCR (Postgres + Redis) |

Any Docker Compose–compatible workload can be adapted to an `arion-compose.nix` file and wired into `linux.nix`.

### OCI containers (direct Podman)

Simpler single-container apps can be declared directly via `virtualisation.oci-containers` without Arion:

- **Navidrome** — music streaming server
- **WebDAV** — file access over HTTPS with password auth
- **Custom app containers** — any image from any registry

### Forgejo + CI runner

The Forgejo arion project is paired with a `gitea-actions-runner` systemd service that runs CI jobs on the host. Labels map `ubuntu-latest` and `ubuntu-22.04` to the local runner so existing GitHub Actions workflows work without changes.

---

## nginx and TLS

All virtual hosts are declared in `nixos/nginx.nix`. The template supports:

- **Reverse proxy** to any localhost port (Arion or OCI containers)
- **Static file serving** from the Nix store or a Pullomatic checkout
- **PHP-FPM** for `.php` files
- **Automatic HTTPS** via Let's Encrypt with DNS-01 challenge (NearlyFreeSpeech provider by default — swap for any supported ACME DNS provider)
- **www → apex redirects** via the `withWww` helper
- Default catch-all vhost that returns 444 for unknown hosts

---

## Personal workspace

The configuration is also a personal workspace manager. Shell environment, aliases, and user accounts are all declared in Nix.

**`nixos/aliases.zsh`** is sourced into zsh on login:

```zsh
alias gs='git status'
alias gco='git checkout'
alias u='cd ..'          # u / uu / uuu / uuuu / uuuuu
function git() { ... }   # expand foo/bar -> https://github.com/foo/bar.git
```

**`nixos/system/users.nix`** declares system users with Home Manager support. SSH authorized keys are loaded from `nixos/keys/authorized_keys/` — drop a `.pub` file in that directory and it applies on the next rebuild.

**Home Manager** is wired in via the flake for per-user dotfiles, shell config, and packages, without touching the global system.

---

## Secrets

Secrets (API keys, passwords, tokens) are encrypted with [agenix](https://github.com/ryantm/agenix) and decrypted at boot using the host's SSH key. Encrypted `.age` files live in `nixos/secrets/` and are never committed in plaintext.

---

## Stack at a glance

| Layer | Tool |
|---|---|
| OS | NixOS 24.11 |
| Flake inputs | nixpkgs, home-manager, arion, disko, agenix, NUR |
| Container runtime | Podman (rootless-compatible socket) |
| Compose layer | Arion (NixOS module) |
| Web server | nginx + PHP-FPM |
| Git pull daemon | Pullomatic |
| TLS | Let's Encrypt via ACME DNS challenge |
| Secrets | agenix |
| Shell | zsh + Home Manager |
| Target provider | Hetzner (QEMU guest, grub, static route) |

---

## Installation

Deploy to a fresh server with [nixos-anywhere](https://github.com/numtide/nixos-anywhere):

```sh
nix --extra-experimental-features 'flakes nix-command' \
  run github:numtide/nixos-anywhere -- \
  --flake .#nixos root@your-server-ip
```

Before deploying, search for `# FIXME` comments throughout the Nix files and replace placeholder values (hostname, domain names, disk UUID, NIC name, timezone, email).

You will also need to create the host SSH keys used by agenix for secret decryption:

```sh
/root/.ssh/id_rsa
/root/.ssh/id_rsa.pub
/root/.ssh/id_rsa_nix   # ed25519 key used by agenix
```

After the initial deploy, subsequent changes apply with:

```sh
./nixos/apply.sh
```
