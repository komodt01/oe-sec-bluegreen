#!/usr/bin/env bash
set -euo pipefail
sudo cp -r $(pwd)/* /opt/oe-app/ || true
