# VPS 遥控器 (Sentinel-X) - 作者:thex

一个功能强大的 Telegram 机器人，用于远程监控和管理 VPS 服务器。

**GitHub 仓库**: https://github.com/MEILOI/VPS_BOT_X

## 功能特性

### 🎮 核心功能
- **系统监控**: CPU、内存、磁盘、网络流量实时监控
- **Docker 管理**: 容器状态查看、启动、停止、日志
- **SSH 安全**: 登录尝试监控、IP 封禁
- **流量管理**: 月度流量统计、预警、校准
- **备份系统**: 自动/手动备份、备份管理
- **端口管理**: 端口状态监控、描述管理

### 🔧 配置管理
- **TG_BOT Token**: 可随时修改 Telegram Bot Token
- **管理员ID**: 可修改管理员 Telegram User ID
- **命令前缀**: 可自定义命令前缀（默认 `/kk`）
- **多VPS支持**: 通过不同命令前缀支持多VPS管理

### 🎯 用户界面
- **Telegram 交互**: 完整的按钮菜单系统
- **KK 控制台**: 服务器端命令行管理界面
- **实时通知**: 系统事件、Docker 事件、安全警报

## 快速开始

### 1. 环境要求
- Linux 系统 (Debian/Ubuntu 推荐)
- Python 3.8+
- Docker (可选，用于容器管理)
- Telegram Bot Token

### 2. 安装步骤

```bash
# 克隆仓库
git clone https://github.com/MEILOI/VPS_BOT_X.git
cd vps_bot-x

# 运行安装脚本
sudo ./install.sh
```

安装脚本将：
- 安装系统依赖
- 配置 Python 环境
- 创建系统服务
- 安装管理脚本 `kk`

### 3. 初始配置

1. **获取 Telegram Bot Token**
   - 在 Telegram 中联系 @BotFather
   - 创建新机器人，获取 Token

2. **获取管理员 User ID**
   - 在 Telegram 中联系 @userinfobot
   - 发送 `/id` 获取您的 User ID

3. **编辑配置文件**
   ```bash
   sudo nano /opt/vps_bot-x/sentinel_config.json
   ```

   示例配置：
   ```json
   {
     "bot_token": "YOUR_BOT_TOKEN",
     "admin_id": YOUR_USER_ID,
     "server_remark": "My VPS",
     "traffic_limit_gb": 1024,
     "command_prefix": "kk"
   }
   ```

### 4. 启动服务

```bash
# 使用 kk 控制台
sudo kk

# 或直接使用 systemctl
sudo systemctl start vpsbot
sudo systemctl enable vpsbot
```

## 使用方法

### Telegram 命令

| 命令 | 功能 | 说明 |
|------|------|------|
| `/b` | 开始使用 | 显示主菜单 |
| `/<prefix>` | 控制台 | 默认 `/kk`，可自定义 |
| `/settoken` | 修改 Token | 格式: `数字:字母数字组合` |
| `/setadminid` | 修改管理员ID | 纯数字格式 |
| `/setprefix` | 修改命令前缀 | 小写字母、数字、下划线 |

### KK 控制台菜单

#### 已安装状态菜单：
```
[1] 启动  [2] 重启  [3] 停止
[4] 日志  [5] 配置  [0] 退出
[6] 更新代码  [7] 修改TG对接键  
[8] 修改管理员ID  [9] 修改命令前缀
[10] 重新安装  [11] 卸载系统
```

#### 未安装状态菜单：
```
[10] 安装系统
[0] 退出
```

#### 新增功能说明：
- **选项10 (安装/重新安装)**: 一键安装系统，包含依赖安装、目录创建、服务配置
- **选项11 (卸载)**: 安全卸载系统，保留配置文件，可选择性删除控制台命令

### 功能模块

#### 1. 系统监控
- 实时系统状态查看
- 资源使用率图表
- 流量统计和预警

#### 2. Docker 管理
- 容器列表和状态
- 容器操作（启动/停止/重启）
- 容器日志查看
- 镜像管理

#### 3. SSH 安全
- 登录尝试监控
- 自动 IP 封禁
- 封禁记录查看
- SSH 密钥管理

#### 4. 备份系统
- 定时自动备份
- 手动备份触发
- 备份文件管理
- 备份恢复功能

#### 5. 流量管理
- 月度流量统计
- 每日流量报告
- 流量使用预警
- 流量数据校准

## 配置说明

### 配置文件路径
- 主配置: `/opt/vps_bot-x/sentinel_config.json`
- SSH 密钥: `/path/to/your/.ssh/authorized_keys`
- 审计日志: `/path/to/your/bot.log`

### 可配置项

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `bot_token` | string | "" | Telegram Bot Token |
| `admin_id` | integer | 0 | 管理员 User ID |
| `server_remark` | string | "VPS_bot-X" | 服务器备注 |
| `traffic_limit_gb` | integer | 1024 | 月度流量限制(GB) |
| `command_prefix` | string | "kk" | 命令前缀 |
| `daily_report_times` | array | ["08:00", "20:00"] | 每日报告时间 |
| `backup_paths` | array | [] | 备份路径列表 |
| `ports` | object | {} | 端口描述映射 |

## 多VPS部署

### 场景：一个Bot管理多个VPS
1. 在每个VPS上安装本系统
2. 为每个VPS设置不同的 `command_prefix`
   - VPS1: `command_prefix: "vps1"`
   - VPS2: `command_prefix: "vps2"`
3. 使用不同的命令管理不同VPS
   - `/vps1` - 管理 VPS1
   - `/vps2` - 管理 VPS2

### 优势
- 统一的管理界面
- 避免命令冲突
- 集中监控多个服务器

## 安全注意事项

### 1. 权限管理
- 仅管理员可访问控制功能
- 所有用户输入都经过验证
- 敏感操作需要确认

### 2. 数据保护
- 配置文件不包含在代码仓库中
- 日志文件定期清理
- 备份文件加密存储（可选）

### 3. 网络安全
- 使用 HTTPS Webhook（推荐）
- IP 访问限制
- 登录尝试监控和封禁

## 故障排除

### 常见问题

#### 1. Bot 无法启动
- 检查 Token 格式是否正确
- 检查 Python 依赖是否安装
- 查看日志: `journalctl -u vpsbot -f`

#### 2. 命令无响应
- 确认 Bot 正在运行
- 检查管理员 ID 配置
- 验证网络连接

#### 3. 流量统计不准确
- 检查 vnstat 是否安装
- 确认网络接口名称
- 手动校准流量数据

### 日志文件
- 系统日志: `journalctl -u vpsbot`
- 应用日志: `/var/log/vps_bot/`
- 错误日志: 查看 Telegram 错误消息

## 更新和维护

### 代码更新
```bash
cd /opt/vps_bot-x
git pull origin main
sudo systemctl restart vpsbot
```

### 数据备份
- 配置文件: `/opt/vps_bot-x/sentinel_config.json`
- 备份文件: 指定备份目录
- 日志文件: 按需备份

### 系统清理
- 定期清理旧日志
- 删除过期备份
- 更新系统依赖

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 贡献指南

欢迎提交 Issue 和 Pull Request！

### 开发环境
1. Fork 本仓库
2. 创建功能分支
3. 提交更改
4. 创建 Pull Request

### 代码规范
- 遵循 PEP 8 Python 代码规范
- 添加适当的注释
- 更新相关文档

## 联系方式

如有问题或建议，请通过以下方式联系：
- GitHub Issues
- Telegram: @your_username

---

**提示**: 在生产环境部署前，请在测试环境充分测试所有功能。