#!/bin/bash

if command -v apt >/dev/null; then sudo apt update && sudo apt install -y curl jq sed grep; \
elif command -v yum >/dev/null; then sudo yum install -y curl jq sed grep; \
elif command -v dnf >/dev/null; then sudo dnf install -y curl jq sed grep; \
elif command -v pacman >/dev/null; then sudo pacman -Sy --noconfirm curl jq sed grep; \
elif command -v apk >/dev/null; then sudo apk add curl jq sed grep; \
elif command -v brew >/dev/null; then brew install curl jq grep; \
else echo "Unsupported OS. Manual installation required."; fi
