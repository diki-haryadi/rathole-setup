# Rathole Installer Scripts

Automated installation scripts for [Rathole](https://github.com/rathole-org/rathole) – a lightweight reverse tunnel tool for accessing services behind NAT/firewalls.

## What is Rathole?

Rathole is a reverse tunnel utility that lets you expose a local service to a remote network without complex VPN setup. Common use cases:

- Access NAS/home media servers from anywhere
- Remote SSH into behind-NAT machines
- Expose local development servers securely
- Build lightweight private tunneling infrastructure

## Quick Start

### Server Setup

On your publicly accessible server:

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/rathole-installer/main/server.sh)
```

The script will:
- Download the latest Rathole binary
- Create a system user and directories
- Generate a secure random token
- Set up systemd auto-start
- Display your token for client configuration

**Output example:**
```
=== Rathole Server Setup Complete ===
Config: /etc/rathole/server.toml
Token: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
Port: 2333

Save this token on your client:
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

### Client Setup

On the machine you want to tunnel from:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/rathole-installer/main/client.sh) \
  myserver.com:2333 \
  your_token_here \
  127.0.0.1:22
```

Arguments:
- `server_addr` – Your server's address and port (required)
- `token` – Generated from server setup (required)
- `local_addr` – Local service to expose (default: 127.0.0.1:22 for SSH)

**After installation:**
```bash
cd ~/rathole
./rathole client.toml
```

Or run in the background:
```bash
nohup ~/rathole/rathole ~/rathole/client.toml > ~/rathole/rathole.log 2>&1 &
```

## Manual Installation

If you prefer not to use automated scripts:

1. Download the latest binary from [rathole releases](https://github.com/rathole-org/rathole/releases)
2. Extract and make executable: `chmod +x rathole`
3. Create configuration files (see examples below)
4. Run: `./rathole config.toml`

## Configuration

### Server Configuration

Edit `/etc/rathole/server.toml`:

```toml
[server]
bind_addr = "0.0.0.0:2333"

[server.services.my_nas_ssh]
token = "your_secure_token_here"
bind_addr = "0.0.0.0:5202"

[server.services.web_server]
token = "different_token_for_web"
bind_addr = "0.0.0.0:8080"
```

### Client Configuration

Edit `~/rathole/client.toml`:

```toml
[client]
remote_addr = "myserver.com:2333"

[client.services.my_nas_ssh]
token = "your_secure_token_here"
local_addr = "127.0.0.1:22"

[client.services.web_server]
token = "different_token_for_web"
local_addr = "127.0.0.1:3000"
```

## Usage Examples

### SSH Tunnel

**Server config:**
```toml
[server.services.home_ssh]
token = "abc123def456"
bind_addr = "0.0.0.0:2222"
```

**Client config:**
```toml
[client.services.home_ssh]
token = "abc123def456"
local_addr = "127.0.0.1:22"
```

**Connect remotely:**
```bash
ssh -p 2222 user@myserver.com
```

### Web Server

**Server config:**
```toml
[server.services.home_web]
token = "web123token456"
bind_addr = "0.0.0.0:8080"
```

**Client config:**
```toml
[client.services.home_web]
token = "web123token456"
local_addr = "192.168.1.100:3000"
```

**Access:** `http://myserver.com:8080`

## Service Management

### Server

```bash
# View status
systemctl status rathole

# Restart
systemctl restart rathole

# View logs
journalctl -u rathole -f

# Stop
systemctl stop rathole
```

### Client

If you set up as a service (optional):

```bash
sudo systemctl restart rathole
sudo journalctl -u rathole -f
```

For background process, check logs:
```bash
tail -f ~/rathole/rathole.log
```

## Security Considerations

⚠️ **Important:**

1. **Tokens**: Use strong, random tokens. The provided scripts generate 16-byte hex tokens (`openssl rand -hex 16`)
2. **Firewall**: Only expose ports you intend to use
3. **HTTPS/TLS**: Rathole itself doesn't provide encryption. For sensitive data, use:
   - SSH tunneling over Rathole
   - HTTPS for web services
   - Other encryption layers as needed
4. **Access Control**: Limit who can reach your server ports (firewall rules, ufw, etc.)
5. **Token Management**: Treat tokens like passwords – don't hardcode in public configs

## Troubleshooting

### Client won't connect

```bash
# Check server is running
ssh user@myserver.com
systemctl status rathole

# Check firewall allows the port
sudo ufw allow 2333/tcp

# View detailed logs
journalctl -u rathole -n 50 --no-pager
```

### Slow speeds or dropped connections

- Check network stability between client and server
- Increase buffer sizes in config (see Rathole docs)
- Monitor resource usage on both ends

### Permission denied errors

- Ensure `rathole` user owns config directories on server
- Check file permissions: `chmod 600 /etc/rathole/token.txt`

## Requirements

- Linux/macOS/Windows (WSL recommended for Windows)
- `bash`, `curl`, `tar`
- For server: root/sudo access to install as systemd service
- For client: user permission to install in `$HOME/rathole`

## Supported Platforms

| OS | Architecture | Status |
|----|--------------|--------|
| Linux | x86_64 | ✓ Tested |
| macOS | x86_64 | ✓ Tested |
| Windows | x86_64 (via WSL) | ✓ Works |

Other architectures may be available – check [rathole releases](https://github.com/rathole-org/rathole/releases).

## Scripts Overview

### `server.sh`
- Requires: root/sudo
- Downloads latest Rathole binary
- Creates `rathole` system user
- Installs as systemd service
- Generates random token
- Saves config to `/etc/rathole/server.toml`

**Usage:**
```bash
sudo bash server.sh
```

### `client.sh`
- Requires: user permissions
- Detects OS/architecture
- Downloads appropriate binary
- Creates config from arguments
- No service installation (manual or via systemd)

**Usage:**
```bash
bash client.sh <server_addr> <token> [local_addr]
```

## Updating

To update to a newer Rathole version, re-run the installation scripts. They will overwrite existing binaries while preserving config files.

## License

These installer scripts are provided as-is. [Rathole](https://github.com/rathole-org/rathole) itself is dual-licensed under MIT/Apache 2.0.

## Contributing

Found a bug or have an improvement? Open an issue or pull request.

## Resources

- **Rathole GitHub**: https://github.com/rathole-org/rathole
- **Rathole Docs**: https://rathole.gitbook.io/
- **Issues & Discussions**: [rathole-org/rathole](https://github.com/rathole-org/rathole/discussions)

## Disclaimer

These scripts automate Rathole installation. Users are responsible for:
- Securing their infrastructure
- Managing tokens and access control
- Complying with local network policies
- Ensuring proper firewall configuration

Use at your own risk.
