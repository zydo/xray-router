# xray-router

中文 | [English](README.en.md)

在路由器上配置一次 [Xray](https://github.com/XTLS/Xray-core) 代理，局域网内所有设备自动使用代理，无需任何客户端设置。

## 概述

本项目将 xray-core 部署为 OpenWrt 路由器上的透明代理（已在 [GL-iNet Flint 2](https://www.gl-inet.com/products/gl-mt6000/) 上测试）。配置完成后，局域网内所有设备自动通过代理路由，无需任何额外设置。

根据您的需要配置任意出站协议（VLESS、VMess、Trojan、Shadowsocks 等）、路由规则和 DNS 设置。

## 快速开始

**注意：** 本仓库专用于在 OpenWrt 路由器上运行。脚本会自动检测路由器架构并下载对应的 Xray-core 二进制文件。

**支持的架构：** `aarch64`、`armv7l`、`mips`/`mipsle`、`mips64`/`mips64le`、`x86_64`、`i686`

```bash
# 克隆仓库到路由器
git clone https://github.com/zydo/xray-router.git
cd xray-router

# 安装 xray-core
./install

# 复制并编辑示例配置
cp config.example.json my-config.json
vi my-config.json  # 或使用您喜欢的编辑器

# 配置并设置 TPROXY
./configure --config=my-config.json

# 完成！局域网内所有设备现在都通过 xray 路由
```

## 配置

### 必需的 TPROXY 入站

您的 `config.json` 必须包含以下透明代理入站配置：

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

此入站配置：

- 监听端口 5201 以接收所有 TCP/UDP 流量
- 使用 TPROXY 模式透明拦截流量
- 启用嗅探以正确处理 HTTP、TLS 和 QUIC 协议
- 与 `xray-tproxy` 脚本配合将局域网流量路由到 xray

### 最小化 VLESS-REALITY-uTLS 示例

以下是出站配置的最小化工作示例：

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

- 将所有占位符值（your.vless-server.com、UUID、密钥等）替换为您的实际服务器配置
- **SNI (`serverNames`)**：您可以继续使用 `www.cloudflare.com`，这是一个合法的高流量网站，或替换为其他 SNI

更多完整配置示例，请参阅：

- [XTLS/Xray-examples](https://github.com/XTLS/Xray-examples) - 配置示例集合

## 仓库结构

```
xray-router/
├── bin/
│   └── xray-tproxy          # TPROXY 脚本（安装到 /usr/bin）
├── init.d/
│   └── xray                 # xray 服务的初始化脚本
├── scripts/
│   └── lib/
│       ├── logging.sh       # 日志函数
│       ├── download.sh      # 下载函数
│       ├── arch.sh          # 架构检测
│       └── common.sh        # 通用工具
├── install                  # 安装 xray-core
├── configure                # 配置 xray 并设置 TPROXY
├── upgrade                  # 升级 xray-core
├── uninstall                # 卸载所有内容
├── config.example.json      # 配置模板
├── README.md                # 中文文档
└── README.en.md             # 英文文档
```

## 脚本说明

### `install`

安装 xray-core 二进制文件、初始化脚本和地理数据库。

```bash
./install [--github-proxy=URL]
```

**选项：**

- `--github-proxy=URL` - 使用 GitHub 镜像下载（例如 [`ghfast.top`](https://ghfast.top/)）

**功能：**

- 自动检测系统架构
- 下载适用于您架构的最新 xray-core
- 安装到 `/usr/bin/xray`，带版本化软链接
- 安装 geoip.dat 和 geosite.dat
- 安装初始化脚本到 `/etc/init.d/xray`

### `upgrade`

将 xray-core 升级到最新版本。

```bash
./upgrade [--github-proxy=URL]
```

**选项：**

- `--github-proxy=URL` - 使用 GitHub 镜像下载（例如 [`ghfast.top`](https://ghfast.top/)）

**功能：**

- 停止 xray 服务
- 下载并安装最新版本
- 使用现有配置重启 xray 服务

### `configure`

配置 xray 并设置 TPROXY。

```bash
./configure --config=PATH
```

**示例：**

```bash
./configure --config=config.json
./configure --config=/path/to/my-config.json
```

**功能：**

1. 验证 xray-core 已安装
2. 使用 xray 验证配置文件
3. 停止现有的 xray 服务和 TPROXY 规则
4. 安装配置到 `/etc/xray/config.json`
5. 启动 xray 服务（通过初始化脚本）
6. **立即运行 xray-tproxy** 设置 TPROXY 规则
7. **将 xray-tproxy 添加到 rc.local** 以便每次重启时自动运行

**为什么 xray-tproxy 需要在启动时运行：**

在某些测试过的 OpenWrt 路由器上，TPROXY iptables 规则不会在重启后持久保存。

### `uninstall`

移除 xray-core、TPROXY 和所有配置。

```bash
./uninstall
```

**移除内容：**

- xray 服务（停止并禁用）
- xray 进程（终止所有运行的进程）
- TPROXY iptables 规则
- TPROXY 策略路由
- 初始化脚本（/etc/init.d/xray）
- xray-tproxy 脚本（/usr/bin/xray-tproxy）
- /etc/rc.local 中的 xray-tproxy
- xray 二进制文件（所有版本和软链接）
- GeoIP 和 GeoSite 数据库文件（所有版本和软链接）
- 配置文件（/etc/xray/config.json）
- 日志目录（/var/log/xray）

**注意：** 您需要输入 'yes' 来确认卸载。

## 重要路径

| 路径 | 用途 |
|------|------|
| `/usr/bin/xray` | xray 二进制文件 |
| `/usr/bin/xray-tproxy` | TPROXY 设置脚本 |
| `/usr/bin/geoip.dat` | GeoIP 数据库 |
| `/usr/bin/geosite.dat` | GeoSite 数据库 |
| `/etc/xray/config.json` | 客户端配置 |
| `/etc/init.d/xray` | 初始化脚本 |
| `/etc/rc.local` | 启动时运行 xray-tproxy |
| `/var/log/xray/` | 日志目录 |

## 故障排除

### 检查 xray 状态

```bash
/etc/init.d/xray status
pidof xray
netstat -an | grep 5201
```

### 检查 TPROXY 状态

```bash
# 检查 TPROXY 规则是否已安装
iptables -t mangle -L XRAY_TPROXY -n -v
iptables -t mangle -L PREROUTING -n -v | grep XRAY_TPROXY
```

### 查看日志

```bash
# xray 服务日志
logread -e xray

# xray-tproxy 脚本日志（通过 logger）
logread | grep xray-tproxy
```

### 重启服务

```bash
# 重启 xray 服务
/etc/init.d/xray restart

# 重新运行 xray-tproxy 脚本以恢复 TPROXY 规则
/usr/bin/xray-tproxy
```

### 检查 TPROXY 包计数器

```bash
iptables -t mangle -L XRAY_TPROXY -n -v -v
```

### 常见问题

**TPROXY 不工作：**

1. 检查 xray 是否正在监听：`netstat -an | grep 5201`
2. 检查 TPROXY 规则是否存在：`iptables -t mangle -L XRAY_TPROXY -n -v`
3. 检查包计数器 - 如果都是 0，说明规则没有匹配流量
4. 重新运行 xray-tproxy 脚本：`/usr/bin/xray-tproxy`

**重启后 TPROXY 规则未恢复：**

1. 检查 `/etc/rc.local` 包含 xray-tproxy 启动
2. 检查 xray 服务是否已启用：`/etc/init.d/xray enabled`

## 许可证

MIT

## 资源

- **OpenWrt:** <https://openwrt.org/>
- **Xray-core:** <https://github.com/XTLS/Xray-core>
- **Xray Examples:** <https://github.com/XTLS/Xray-examples>
