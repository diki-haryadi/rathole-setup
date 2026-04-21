#!/usr/bin/env bash
set -e

# Rathole reverse tunnel server installer
RATHOLE_VERSION="dev-latest"
INSTALL_DIR="/opt/rathole"
CONFIG_FILE="/etc/rathole/server.toml"
SERVICE_FILE="/etc/systemd/system/rathole.service"
SERVER_PORT="2333"
SERVICE_PORT="5202"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Check if already installed
if command -v $INSTALL_DIR/rathole &> /dev/null; then
    read -p "Rathole is already installed. Continue with reinstall? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo "Setting up Rathole server..."
echo

# Generate token
TOKEN=$(openssl rand -hex 16)
echo "Generated token: $TOKEN"

# Create user if it doesn't exist
if ! id -u rathole &>/dev/null; then
    useradd -r -s /bin/false rathole
    echo "Created rathole user"
fi

# Create directories
mkdir -p $INSTALL_DIR
mkdir -p /etc/rathole

# Download and extract
echo "Fetching Rathole from GitHub..."
cd /tmp
rm -f rathole.tar.gz rathole 2>/dev/null || true

if ! curl -sL -o rathole.tar.gz https://github.com/rathole-org/rathole/releases/download/${RATHOLE_VERSION}/rathole-dev-x86_64-unknown-linux-gnu.tar.gz; then
    echo "Download failed. Check your internet connection."
    exit 1
fi

tar -xzf rathole.tar.gz || {
    echo "Failed to extract archive"
    exit 1
}

chmod +x rathole
mv rathole $INSTALL_DIR/

# Write configuration
cat > $CONFIG_FILE <<EOF
[server]
bind_addr = "0.0.0.0:${SERVER_PORT}"

[server.services.my_nas_ssh]
token = "${TOKEN}"
bind_addr = "0.0.0.0:${SERVICE_PORT}"
EOF

# Save token
echo "$TOKEN" > /etc/rathole/token.txt
chmod 600 /etc/rathole/token.txt

# Set permissions
chown -R rathole:rathole $INSTALL_DIR
chown -R rathole:rathole /etc/rathole

# Create systemd service
cat > $SERVICE_FILE <<EOF
[Unit]
Description=Rathole reverse tunnel server
After=network.target

[Service]
Type=simple
User=rathole
ExecStart=${INSTALL_DIR}/rathole ${CONFIG_FILE}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start service
systemctl daemon-reload
systemctl enable rathole
systemctl restart rathole

sleep 2

# Check status
if systemctl is-active --quiet rathole; then
    echo "✓ Service started successfully"
else
    echo "✗ Service failed to start. Check logs:"
    journalctl -u rathole -n 20 --no-pager
    exit 1
fi

echo
echo "=== Rathole Server Setup Complete ==="
echo "Config: $CONFIG_FILE"
echo "Token: $TOKEN"
echo "Port: $SERVER_PORT"
echo
echo "Save this token on your client:"
echo "$TOKEN"
echo
echo "View logs: journalctl -u rathole -f"
echo "Restart: systemctl restart rathole"
