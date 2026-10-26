#!/bin/sh
set -e
cd "$(dirname "$0")/.."
bin="${POSTURE_BIN:-$HOME/.local/bin}"
mkdir -p "$bin"
./scripts/bundle.sh
ln -sf "$PWD/.build/release/posture" "$bin/posture"
echo "posture -> $bin/posture"
case ":$PATH:" in *":$bin:"*) ;; *) echo "add $bin to your PATH" ;; esac
open "$HOME/Applications/Posture.app"
