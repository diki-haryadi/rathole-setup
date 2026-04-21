#!/usr/bin/env bash
set -e

# Rathole client installer
# Usage: ./install-client.sh [server_addr] [token] [local_addr]

SERVER_ADDR="${1:-myserver.com:2333}"
TOKEN="${2:-}"
LOCAL_ADDR="${3:-127.0.0.1:22}"
INSTALL_DIR="$HOME/rathole"
CONFIG_FILE="$INSTALL_DIR/client.toml"

# Validate inputs
if [[ -z "$TOKEN" ]]; then
    echo "Error: Token not provided"
    echo "Usage: $0 <server_addr> <token> [local_addr]"
    exit 1
fi

# Detect platform
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS" in
    Linux)
        PLATFORM="x86_64-unknown-linux-gnu"
        BIN="rathole"
        ;;
    Darwin)
        PLATFORM="x86_64-apple-darwin"
        BIN="rathole"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        PLATFORM="x86_64-pc-windows-msvc"
        BIN="rathole.exe"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

echo "Setting up Rathole client..."
echo "Platform: $OS ($ARCH)"
echo

# Create directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Download
echo "Downloading Rathole..."
URL="https://github.com/rathole-org/rathole/releases/download/dev-latest/rathole-dev-${PLATFORM}.tar.gz"

if ! curl -fsSL -o rathole.tar.gz "$URL"; then
    echo "Download failed. Check your connection and platform."
    exit 1
fi

# Extract
if ! tar -xzf rathole.tar.gz; then
    echo "Failed to extract archive"
    exit 1
fi

# Make executable on Unix
if [[ "$BIN" == "rathole" ]]; then
    chmod +x rathole
fi

# Create config
cat > "$CONFIG_FILE" <<EOF
[client]
remote_addr = "${SERVER_ADDR}"

[client.services.my_nas_ssh]
token = "${TOKEN}"
local_addr = "${LOCAL_ADDR}"
EOF

echo "✓ Installation complete"
echo
echo "Config: $CONFIG_FILE"
echo "Binary: $INSTALL_DIR/$BIN"
echo
echo "To start:"
echo "  cd $INSTALL_DIR && ./$BIN client.toml"
echo
echo "To run in background:"
if [[ "$BIN" == "rathole.exe" ]]; then
    echo "  $INSTALL_DIR\\rathole.exe client.toml &"
else
    echo "  nohup $INSTALL_DIR/rathole client.toml &"
fi
