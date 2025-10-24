#!/usr/bin/env bash
set -euo pipefail
sudo pkill -f 'http.server' || true
nohup python3 -m http.server 8080 --directory /opt/oe-app >/var/log/oe-app.log 2>&1 &
