#!/usr/bin/env bash

set -e

nix-shell -p alejandra.out --run 'alejandra .'
