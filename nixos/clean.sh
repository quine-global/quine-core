#!/usr/bin/env bash

set -e

nix-store --gc
nix-collect-garbage -d
rm -rf ~/.cache/nix
rm -rf /nix/var/nix/gcroots/*
