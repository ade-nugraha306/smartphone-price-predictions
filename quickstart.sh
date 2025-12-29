#!/usr/bin/env bash
set -e

echo "🚀 Smartphone Price Predictor — Dev Runner"

if [[ ! -f "script/unix.sh" ]]; then
  echo "unix script not found"
  exit 1
fi

chmod +x script/unix.sh
exec script/unix.sh
