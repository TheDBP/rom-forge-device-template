#!/usr/bin/env bash
# Convenience shim -> the forge orchestrator. Logic lives in forge/; per-device config is
# ./device.conf. Run `./bootstrap.sh` or `./forge/bootstrap.sh` — same thing.
exec "$(cd "$(dirname "$0")" && pwd)/forge/bootstrap.sh" "$@"
