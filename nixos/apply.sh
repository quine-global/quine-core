#!/usr/bin/env bash

set -e

git pull origin main
nixos-rebuild switch --flake .#nixos --verbose --show-trace
