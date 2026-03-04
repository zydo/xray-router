# xray-router

[中文](README.md) | English

Configure your [Xray](https://github.com/XTLS/Xray-core) proxy once on the router, and all LAN devices automatically use it - no client-side setup needed.

## Overview

This project deploys xray-core as a transparent proxy on OpenWrt routers (tested on [GL-iNet Flint 2](https://www.gl-inet.com/products/gl-mt6000/)). Once configured, all devices on your LAN automatically route through the proxy without any per-device setup.

Configure any outbound protocol (VLESS, VMess, Trojan, Shadowsocks, etc.), routing rules, and DNS settings according to your needs.

## Quick Start

**Note:** This repository is dedicated to running on OpenWrt routers.

**Supported architectures:** `aarch64`, `armv7l`, `mips`/`mipsle`, `mips64`/`mips64le`, `x86_64`, `i686`

```bash
# Clone repository to your router
git clone https://github.com/zydo/xray-router.git
cd xray-router

# Install xray-core
./install

# Copy and edit the example configuration
cp config.example.json my-config.json
vi my-config.json  # or use your preferred editor

# Configure and setup TPROXY 
./configure --config=my-config.json

# Done! All LAN devices are now routed through xray
```

## Configuration

### Required TPROXY Inbound

Your `config.json` must include this transparent proxy inbound configuration:

```json
{
  "inbounds": [
    {
      "tag": "tproxy",
      "port": 5201,
      "protocol": "dokodemo-door",
      "settings": {
        "network": "tcp,udp",
        "followRedirect": true
      },
      "streamSettings": {
        "sockopt": {
          "tproxy": "tproxy"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"]
      }
    }
  ]
}
```

This inbound configuration:

- Listens on port 5201 for all TCP/UDP traffic
- Uses TPROXY mode to transparently intercept traffic
- Enables sniffing to properly handle protocols like HTTP, TLS, and QUIC
- Works with the `xray-tproxy` script to route LAN traffic through xray

### Minimal VLESS-REALITY-uTLS Example

Here's a minimal working example for the outbound configuration:

```json
{
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "your.vless-server.com",
            "port": 443,
            "users": [
              {
                "id": "your-uuid-here",
                "encryption": "none",
                "flow": "xtls-rprx-vision",
                "Reality settings": {
                  "publicKey": "your-public-key-here",
                  "shortId": "your-short-id-here",
                  "serverNames": ["www.cloudflare.com"],
                  "fingerprint": "chrome"
                }
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "www.cloudflare.com:443",
          "serverNames": ["www.cloudflare.com"],
          "privateKey": "your-private-key-here",
          "shortIds": ["your-short-id-here"]
        }
      }
    }
  ]
}
```

- Replace all placeholder values (your.vless-server.com, UUID, keys, etc.) with your actual server configuration
- **SNI (`serverNames`)**: You can keep using `www.cloudflare.com` as it's a legitimate, high-traffic website, or replace with other SNI.

For complete configuration examples, see:

- [XTLS/Xray-examples](https://github.com/XTLS/Xray-examples) - Collection of example configurations

## Repository Structure

```
xray-router/
├── bin/
│   └── xray-tproxy          # TPROXY script (installed to /usr/bin)
├── init.d/
│   └── xray                 # Init script for xray service
├── scripts/
│   └── lib/
│       ├── logging.sh       # Logging functions
│       ├── download.sh      # Download functions
│       ├── arch.sh          # Architecture detection
│       └── common.sh        # Common utilities
├── install                  # Install xray-core
├── configure                # Configure xray and setup TPROXY
├── upgrade                  # Upgrade xray-core
├── uninstall                # Uninstall everything
├── config.example.json      # Configuration template
├── README.md                # Chinese documentation
└── README.en.md             # English documentation
```

## Scripts

### `install`

Install xray-core binary, init scripts, and geo databases.

```bash
./install [--github-proxy=URL]
```

**Options:**

- `--github-proxy=URL` - Use GitHub mirror for downloads (e.g., [`ghfast.top`](https://ghfast.top/))

**What it does:**

- Automatically detects system architecture
- Downloads latest xray-core for your architecture
- Installs to `/usr/bin/xray` with versioned symlinks
- Installs geoip.dat and geosite.dat
- Installs init script to `/etc/init.d/xray`

### `upgrade`

Upgrade xray-core to the latest version.

```bash
./upgrade [--github-proxy=URL]
```

**Options:**

- `--github-proxy=URL` - Use GitHub mirror for downloads (e.g., [`ghfast.top`](https://ghfast.top/))

**What it does:**

- Stops xray service
- Downloads and installs latest version
- Restarts xray service with existing config

### `configure`

Configure xray and setup TPROXY.

```bash
./configure --config=PATH
```

**Examples:**

```bash
./configure --config=config.json
./configure --config=/path/to/my-config.json
```

**What it does:**

1. Validates xray-core is installed
2. Validates config file with xray
3. Stops existing xray service and TPROXY rules
4. Installs config to `/etc/xray/config.json`
5. Starts xray service (via init script)
6. **Runs xray-tproxy immediately** to set up TPROXY rules
7. **Adds xray-tproxy to rc.local** so it runs automatically on every reboot

**Why xray-tproxy needs to run on boot:**

TPROXY iptables rules do not persist across reboots on some tested OpenWrt routers.

### `uninstall`

Remove xray-core, TPROXY, and all configuration.

```bash
./uninstall
```

**What it removes:**

- xray service (stops and disables)
- xray processes (kills any running)
- TPROXY iptables rules
- TPROXY policy routing
- Init scripts (/etc/init.d/xray)
- xray-tproxy script (/usr/bin/xray-tproxy)
- xray-tproxy from /etc/rc.local
- xray binaries (all versions and symlinks)
- GeoIP and GeoSite database files (all versions and symlinks)
- Configuration file (/etc/xray/config.json)
- Log directory (/var/log/xray)

## Important Paths

| Path | Purpose |
|------|---------|
| `/usr/bin/xray` | xray binary |
| `/usr/bin/xray-tproxy` | TPROXY setup script |
| `/usr/bin/geoip.dat` | GeoIP database |
| `/usr/bin/geosite.dat` | GeoSite database |
| `/etc/xray/config.json` | Client configuration |
| `/etc/init.d/xray` | Init script |
| `/etc/rc.local` | Runs xray-tproxy at boot |
| `/var/log/xray/` | Log directory |

## Troubleshooting

### Check xray status

```bash
/etc/init.d/xray status
pidof xray
netstat -an | grep 5201
```

### Check TPROXY status

```bash
# Check if TPROXY rules are installed
iptables -t mangle -L XRAY_TPROXY -n -v
iptables -t mangle -L PREROUTING -n -v | grep XRAY_TPROXY
```

### View logs

```bash
# xray service logs
logread -e xray

# xray-tproxy script logs (via logger)
logread | grep xray-tproxy
```

### Restart services

```bash
# Restart xray service
/etc/init.d/xray restart

# Re-run xray-tproxy script to restore TPROXY rules
/usr/bin/xray-tproxy
```

### Check TPROXY packet counters

```bash
iptables -t mangle -L XRAY_TPROXY -n -v -v
```

### Common Issues

**TPROXY not working:**

1. Check if xray is listening: `netstat -an | grep 5201`
2. Check TPROXY rules exist: `iptables -t mangle -L XRAY_TPROXY -n -v`
3. Check packet counters - if all 0, rules aren't matching traffic
4. Re-run xray-tproxy script: `/usr/bin/xray-tproxy`

**TPROXY rules not restored after reboot:**

1. Check `/etc/rc.local` contains xray-tproxy startup
2. Check xray service is enabled: `/etc/init.d/xray enabled`

## License

MIT

## Resources

- **OpenWrt:** <https://openwrt.org/>
- **Xray-core:** <https://github.com/XTLS/Xray-core>
- **Xray Examples:** <https://github.com/XTLS/Xray-examples>
