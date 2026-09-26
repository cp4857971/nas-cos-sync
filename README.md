# NAS-COS Sync（相册云同步）v2.6.1

> 腾讯云 CloudBase 扩展插件包（.fpk）｜适用于 fnOS（飞牛 OS）等 NAS 应用中心手动安装
> rclone 增量同步至 S3 兼容云存储 + 网页图库 + Cloudflare Tunnel / FRP 公网直连

本仓库用于托管 `nas-cos-sync.fpk` 插件包与完整说明文档。插件包本体（约 55MB 二进制）以 **Release 附件**形式发布。

## 功能特性

- **定时增量同步**：基于 rclone `copy`（`--transfers 8`），默认每 300 秒（5 分钟）增量同步一次，周期可配置
- **15 家 S3 兼容云存储**：腾讯云 COS、阿里云 OSS、AWS S3、Cloudflare R2、MinIO、华为云 OBS、七牛云 Kodo、百度云 BOS、UCloud UFile、金山云 KS3、青云 QingStor、Wasabi、Backblaze B2、DigitalOcean Spaces、其他 S3 兼容
- **网页图库**：内置 Python HTTP 图库（默认端口 8899），支持 jpg/jpeg/png/gif/webp/bmp/heic/heif/tiff/tif；灯箱预览、键盘导航（←/→/Esc）、照片计数、`/api/sync` 手动触发同步
- **存储桶模式**：开启后每次同步自动生成画廊首页 `index.html` 并上传到桶根目录，配合云商静态网站托管即可公网访问，无需 NAS 开机
- **三种公网方案**：Cloudflare Tunnel（Zero Trust）、FRP（任意云商 VPS 跑 frps）、Lucky 反向代理
- **Native 运行**：直接运行在 NAS 上，无需 Docker；以专用用户 `nas-cos-sync` 运行
- **密钥安全**：云存储密钥通过 `rclone.env` 环境变量注入（`RCLONE_CONFIG_COS_*`），不写入脚本

## 使用教程

- [相册云同步配置图文教程（PDF）](./相册云同步配置图文教程.pdf)：从安装、云存储配置到图库与公网访问的分步图文说明。

## 运行模式

| 模式 | 说明 |
|---|---|
| `full` | 完整模式：同步 + 图库 + 公网 |
| `cos` | COS 模式：仅同步到云存储，不开图库 |
| `lan` | 局域网模式：仅图库，不开同步和公网 |
| `proxy` | 反代模式：图库 + 公网隧道，不删云同步 |

## 包结构

```
nas-cos-sync.fpk                     # gzip 压缩包（55,018,629 字节）
├── manifest                         # 元数据（appname=nas-cos-sync, version=2.6.1, checksum）
├── app.tgz                          # 应用本体
│   ├── bin/
│   │   ├── rclone                   # 云存储同步引擎（约 85MB）
│   │   ├── cloudflared              # Cloudflare Tunnel 客户端（约 39MB）
│   │   └── frpc                     # FRP 内网穿透客户端（约 15MB）
│   ├── gallery.py                   # 网页图库服务（HTTP, 端口 8899）
│   ├── build_gallery.py             # 生成 index.html 并上传桶根（存储桶模式）
│   ├── sync.sh                      # 常驻定时增量同步脚本
│   ├── sync-now.sh                  # 手动触发一次同步
│   └── config/                      # privilege（运行用户）
├── cmd/                             # 生命周期脚本（main / config / install / uninstall / upgrade 的 init 与 callback）
├── config/                          # privilege（运行用户 nas-cos-sync）
├── wizard/                          # 安装/配置向导 JSON（云存储配置表单）
└── ICON.PNG / ICON_256.PNG          # 应用图标
```

## 安装

1. 在 NAS 应用中心（fnOS）选择「手动安装第三方包」，上传 `nas-cos-sync.fpk`（从下方 Releases 下载）
2. 安装完成后进入配置向导，填写云存储信息
3. 修改配置后需在应用中心 **停止 → 再启动** 应用生效

### 配置项

| 字段 | 说明 |
|---|---|
| 运行模式 | full / cos / lan / proxy |
| 同步源目录 | NAS 本机相册/照片路径（如 `/vol3/1000/图片/1`） |
| 云服务商 + access_key_id + secret_access_key + endpoint | 目标云存储凭证 |
| bucket / 同步目标路径 | 存储桶名称与桶内相对路径（默认 `/`） |
| 同步周期 | 秒，默认 300 |
| 图库端口 / 图库标题 | 默认 8899 / "NAS 相册" |
| 存储桶模式 | 开启后画廊首页自动上传到桶 |
| Cloudflare Tunnel 令牌 | 可选，创建隧道后将域名指向 `http://localhost:8899` |
| FRP 服务器地址/端口/令牌/远程端口 | 可选，VPS 需运行 frps |

### 环境变量（rclone.env）

| 变量 | 默认值 | 说明 |
|---|---|---|
| `SYNC_SOURCE` | `/` | 同步源目录 |
| `SYNC_TARGET` | `/` | 桶内目标路径 |
| `SYNC_INTERVAL` | `300` | 同步周期（秒） |
| `RCLONE_CONFIG_COS_BUCKET` | — | 存储桶名称 |
| `GALLERY_PORT` | `8899` | 图库端口 |
| `GALLERY_TITLE` | `NAS 相册` | 图库标题 |
| `BUCKET_GALLERY` | `false` | 存储桶模式开关 |

配置文件位于 `${TRIM_PKGVAR}`（如 `/var/packages/nas-cos-sync/var`）：`rclone.conf` + `rclone.env`。

## 公网访问

- **Cloudflare Tunnel**：Cloudflare Zero Trust → Networks → Tunnels 创建隧道，公网域名指向 `http://localhost:8899`，隧道 token 填入配置
- **FRP**：任意云商 VPS 运行 `frps`，NAS 自动运行 `frpc`，通过 `http://VPS_IP:远程端口` 访问
- **Lucky 反代**：Lucky 作为独立应用安装，添加反向代理规则，目标地址 `http://127.0.0.1:8899`，绑定域名即可

## 手动触发同步

```bash
# 终端 / 宝塔 / 1Panel 均可调用
/var/packages/nas-cos-sync/app/sync-now.sh
# 或通过图库接口
curl http://NAS_IP:8899/api/sync
```

## 下载与发布

插件包本体（约 55MB）以 Release 附件形式发布，直接下载：

```bash
# 方式一：Release 附件（推荐，长期有效）
curl -L -o nas-cos-sync.fpk \
  "https://github.com/cp4857971/nas-cos-sync/releases/download/v2.6.1/nas-cos-sync.fpk"

# 方式二：校验完整性（GitHub 已自动生成 SHA-256）
sha256sum nas-cos-sync.fpk
# cc147a97a3e909dfd0bd2e4b5bc1a17e193d57d8b3001dccf5688adf9bfce470
```

发布新版本：`bash scripts/push-fpk.sh [fpk路径] [版本号]`（自动放入 `releases/` 并打 tag；Release 附件可在 GitHub Releases 页面附加）。

### 校验值

| 算法 | 值 |
|---|---|
| MD5 | `67eb64889f2d0691e10c162f9faec123` |
| SHA-256 | `cc147a97a3e909dfd0bd2e4b5bc1a17e193d57d8b3001dccf5688adf9bfce470` |
| 大小 | 55,018,629 字节 |

## 支持本项目

如果这个插件帮到了你，欢迎请作者喝杯咖啡 ☕ 扫一扫即可：

| 微信支付 | 支付宝 |
|---|---|
| ![微信收款码](donate-wechat.jpg) | ![支付宝收款码](donate-alipay.jpg) |

你的支持是对开源项目最大的鼓励！

## 版本历史

| 版本 | 说明 |
|---|---|
| [v2.6.1](https://github.com/cp4857971/nas-cos-sync/releases/tag/v2.6.1) | 当前版本（Release 附件：nas-cos-sync.fpk） |

## 脚本速览

- `sync.sh`：常驻循环，配置就绪后每 `SYNC_INTERVAL` 秒增量同步；存储桶模式开启时同步后生成并上传画廊首页
- `sync-now.sh`：手动触发一次同步
- `gallery.py`：图库 Web 服务（`/` 画廊、`/image?path=` 原图、`/api/sync` 手动同步）
- `build_gallery.py`：生成画廊 `index.html` 并以 `Content-Type: text/html` 上传到桶根
