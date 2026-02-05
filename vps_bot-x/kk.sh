#!/bin/bash
# VPS遥控器控制台脚本 (完整功能版) 作者:thex

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置文件路径
CONFIG_FILE="/opt/vps_bot-x/sentinel_config.json"
INSTALL_DIR="/opt/vps_bot-x"
SERVICE_NAME="vpsbot"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# 检查是否已安装
check_installed() {
    if [ -f "$SERVICE_FILE" ] && [ -d "$INSTALL_DIR" ]; then
        return 0  # 已安装
    else
        return 1  # 未安装
    fi
}

# 读取当前配置
get_config_value() {
    local key="$1"
    python3 -c "
import json
try:
    with open('$CONFIG_FILE', 'r', encoding='utf-8') as f:
        config = json.load(f)
    print(config.get('$key', ''))
except:
    print('')
" 2>/dev/null
}

# 更新配置函数
update_config() {
    local key="$1"
    local value="$2"
    python3 -c "
import json
try:
    with open('$CONFIG_FILE', 'r', encoding='utf-8') as f:
        config = json.load(f)
    config['$key'] = '$value'
    with open('$CONFIG_FILE', 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    print('success')
except Exception as e:
    print(f'error: {e}')
" 2>/dev/null
}

# 备份配置文件
backup_config() {
    local timestamp=$(date +%Y%m%d%H%M%S)
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.$timestamp"
    echo -e "${GREEN}✓ 配置文件已备份: ${CONFIG_FILE}.bak.$timestamp${NC}"
}

# 验证输入函数
validate_token() {
    local token="$1"
    if [[ "$token" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_admin_id() {
    local id="$1"
    if [[ "$id" =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_prefix() {
    local prefix="$1"
    if [[ "$prefix" =~ ^[a-z0-9_]{3,20}$ ]]; then
        return 0
    else
        return 1
    fi
}

while true; do
    clear
    
    # 检查安装状态
    if check_installed; then
        INSTALL_STATUS="${GREEN}● 已安装${NC}"
        # 获取服务状态
        if systemctl is-active --quiet vpsbot; then
            STATUS_TEXT="${GREEN}● 运行中${NC}"
        else
            STATUS_TEXT="${RED}● 已停止${NC}"
        fi
    else
        INSTALL_STATUS="${RED}● 未安装${NC}"
        STATUS_TEXT="${YELLOW}● 未安装${NC}"
    fi
    
    # 获取当前配置值（如果已安装）
    if check_installed && [ -f "$CONFIG_FILE" ]; then
        CURRENT_TOKEN=$(get_config_value "bot_token")
        CURRENT_ADMIN_ID=$(get_config_value "admin_id")
        CURRENT_PREFIX=$(get_config_value "command_prefix")
        if [ -z "$CURRENT_PREFIX" ]; then
            CURRENT_PREFIX="kk"
        fi
    else
        CURRENT_TOKEN="未配置"
        CURRENT_ADMIN_ID="未配置"
        CURRENT_PREFIX="kk"
    fi
    
    # 显示菜单
    echo -e "${CYAN}================================${NC}"
    echo -e "     VPS 遥控器-X 控制台"
    echo -e "     安装: $INSTALL_STATUS  状态: $STATUS_TEXT"
    echo -e "${CYAN}================================${NC}"
    
    if check_installed; then
        echo -e "  [1] 启动  [2] 重启  [3] 停止"
        echo -e "  [4] 日志  [5] 配置  [0] 退出"
        echo -e "  [6] 更新代码"
        echo -e "  [7] 修改TG对接键"
        echo -e "  [8] 修改管理员ID"
        echo -e "  [9] 修改命令前缀"
        echo -e "  [10] 重新安装"
        echo -e "  [11] 卸载系统"
    else
        echo -e "  [10] 安装系统"
        echo -e "  [0] 退出"
    fi
    
    echo -e "${CYAN}--------------------------------${NC}"
    if check_installed; then
        echo -e "  当前配置:"
        echo -e "  TG对接键: ${YELLOW}${CURRENT_TOKEN:0:10}...${NC}"
        echo -e "  管理员ID: ${YELLOW}$CURRENT_ADMIN_ID${NC}"
        echo -e "  命令前缀: ${YELLOW}$CURRENT_PREFIX${NC}"
    else
        echo -e "  ${YELLOW}系统未安装，请选择 [10] 进行安装${NC}"
    fi
    echo -e "${CYAN}================================${NC}"
    
    if check_installed; then
        read -p "请选择 [0-11]: " choice
    else
        read -p "请选择 [0,10]: " choice
    fi
    
    case $choice in
        1)
            echo -e "${GREEN}>>> 正在启动服务...${NC}"
            systemctl start vpsbot
            sleep 1
            ;;
        2)
            echo -e "${GREEN}>>> 正在重启服务...${NC}"
            systemctl restart vpsbot
            sleep 1
            ;;
        3)
            echo -e "${YELLOW}>>> 正在停止服务...${NC}"
            systemctl stop vpsbot
            sleep 1
            ;;
        4)
            echo -e "${CYAN}>>> 显示服务日志 (Ctrl+C 退出)...${NC}"
            journalctl -u vpsbot -f -n 50
            ;;
        5)
            echo -e "${CYAN}>>> 编辑配置文件...${NC}"
            nano "$CONFIG_FILE"
            echo -e "${YELLOW}⚠ 配置已修改，需要重启服务生效${NC}"
            ;;
        6)
            echo -e "${CYAN}>>> 更新代码...${NC}"
            read -p "确认更新代码？(y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${GREEN}>>> 从 GitHub 仓库更新代码...${NC}"
                bash <(curl -fsSL https://raw.githubusercontent.com/MEILOI/VPS_BOT_X/main/vps_bot-x/install.sh)
            else
                echo -e "${YELLOW}更新已取消${NC}"
            fi
            ;;
        7)
            echo -e "${CYAN}>>> 修改TG对接键${NC}"
            echo -e "${YELLOW}格式: 数字:字母数字组合 (例如: 1234567890:ABCdefGHIjklMNOpqr)${NC}"
            echo -e "${YELLOW}⚠ 如果一BOT管理多VPS，请确保配置正确${NC}"
            read -p "请输入新的TG_BOT Token: " new_token
            
            if validate_token "$new_token"; then
                backup_config
                result=$(update_config "bot_token" "$new_token")
                if [ "$result" = "success" ]; then
                    echo -e "${GREEN}✓ TG对接键已更新${NC}"
                    echo -e "${YELLOW}⚠ 需要重启服务生效${NC}"
                else
                    echo -e "${RED}✗ 更新失败: $result${NC}"
                fi
            else
                echo -e "${RED}✗ Token格式无效${NC}"
                echo -e "正确格式: 数字:字母数字组合"
            fi
            read -p "按回车继续..."
            ;;
        8)
            echo -e "${CYAN}>>> 修改管理员ID${NC}"
            echo -e "${YELLOW}格式: 纯数字 (例如: 12345678)${NC}"
            echo -e "${YELLOW}提示: 使用 @userinfobot 获取您的User ID${NC}"
            read -p "请输入新的管理员ID: " new_id
            
            if validate_admin_id "$new_id"; then
                backup_config
                result=$(update_config "admin_id" "$new_id")
                if [ "$result" = "success" ]; then
                    echo -e "${GREEN}✓ 管理员ID已更新${NC}"
                    echo -e "${YELLOW}⚠ 需要重启服务生效${NC}"
                else
                    echo -e "${RED}✗ 更新失败: $result${NC}"
                fi
            else
                echo -e "${RED}✗ ID格式无效，必须是纯数字${NC}"
            fi
            read -p "按回车继续..."
            ;;
        9)
            echo -e "${CYAN}>>> 修改命令前缀${NC}"
            echo -e "${YELLOW}格式: 小写字母、数字、下划线，3-20字符${NC}"
            echo -e "${YELLOW}示例: vps1, mybot, server_01${NC}"
            echo -e "${YELLOW}⚠ 如果一BOT管理多VPS，请为每个VPS设置不同前缀${NC}"
            read -p "请输入新的命令前缀: " new_prefix
            
            if validate_prefix "$new_prefix"; then
                backup_config
                result=$(update_config "command_prefix" "$new_prefix")
                if [ "$result" = "success" ]; then
                    echo -e "${GREEN}✓ 命令前缀已更新为: $new_prefix${NC}"
                    echo -e "${YELLOW}⚠ 需要重启服务生效${NC}"
                    echo -e "${YELLOW}⚠ 重启后使用 /${new_prefix} 访问控制台${NC}"
                else
                    echo -e "${RED}✗ 更新失败: $result${NC}"
                fi
            else
                echo -e "${RED}✗ 前缀格式无效${NC}"
                echo -e "要求: 小写字母、数字、下划线，3-20字符"
            fi
            read -p "按回车继续..."
            ;;
        10)
            if check_installed; then
                echo -e "${YELLOW}>>> 重新安装系统${NC}"
                echo -e "${RED}⚠ 警告: 这将覆盖现有安装${NC}"
                echo -e "${RED}⚠ 配置文件将保留，但代码会被更新${NC}"
            else
                echo -e "${GREEN}>>> 安装系统${NC}"
            fi
            
            read -p "确认继续？(y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${CYAN}>>> 开始安装/重新安装...${NC}"
                
                # 安装依赖
                echo -e "${GREEN}1. 安装系统依赖...${NC}"
                apt update -y > /dev/null 2>&1
                apt install -y python3 python3-pip curl nano git vnstat nethogs iptables net-tools > /dev/null 2>&1
                
                # 安装 Python 包
                echo -e "${GREEN}2. 安装 Python 依赖...${NC}"
                pip3 install python-telegram-bot psutil requests netifaces --break-system-packages > /dev/null 2>&1
                
                # 创建安装目录
                echo -e "${GREEN}3. 创建目录结构...${NC}"
                mkdir -p "$INSTALL_DIR"
                
                # 复制当前目录的文件（假设 kk.sh 在正确的位置）
                SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
                if [ "$SCRIPT_DIR" != "$INSTALL_DIR" ]; then
                    echo -e "${GREEN}4. 复制代码文件...${NC}"
                    cp -r "$SCRIPT_DIR"/* "$INSTALL_DIR"/ 2>/dev/null || true
                fi
                
                # 创建配置文件（如果不存在）
                if [ ! -f "$CONFIG_FILE" ]; then
                    echo -e "${GREEN}5. 创建默认配置文件...${NC}"
                    cat > "$CONFIG_FILE" << EOF
{
  "bot_token": "",
  "admin_id": 0,
  "server_remark": "VPS遥控器-X",
  "traffic_limit_gb": 1024,
  "command_prefix": "kk"
}
EOF
                    echo -e "${YELLOW}⚠ 请编辑 $CONFIG_FILE 配置 Token 和 Admin ID${NC}"
                fi
                
                # 创建 systemd 服务
                echo -e "${GREEN}6. 创建系统服务...${NC}"
                cat > "$SERVICE_FILE" << EOF
[Unit]
Description=VPS遥控器 Telegram Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 $INSTALL_DIR/main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
                
                # 重载 systemd
                systemctl daemon-reload
                systemctl enable "$SERVICE_NAME"
                
                echo -e "${GREEN}✅ 安装完成！${NC}"
                echo -e "${YELLOW}下一步:${NC}"
                echo -e "1. 编辑配置文件: nano $CONFIG_FILE"
                echo -e "2. 设置 Telegram Bot Token 和 Admin ID"
                echo -e "3. 启动服务: systemctl start $SERVICE_NAME"
            else
                echo -e "${YELLOW}安装已取消${NC}"
            fi
            read -p "按回车继续..."
            ;;
        11)
            if ! check_installed; then
                echo -e "${RED}系统未安装，无需卸载${NC}"
                read -p "按回车继续..."
                continue
            fi
            
            echo -e "${RED}>>> 卸载系统${NC}"
            echo -e "${RED}⚠ 警告: 这将删除所有安装文件和服务${NC}"
            echo -e "${RED}⚠ 配置文件将保留在 $CONFIG_FILE${NC}"
            
            read -p "确认卸载？(输入 'YES' 确认): " confirm
            if [ "$confirm" = "YES" ]; then
                echo -e "${CYAN}>>> 开始卸载...${NC}"
                
                # 停止服务
                echo -e "${GREEN}1. 停止服务...${NC}"
                systemctl stop "$SERVICE_NAME" 2>/dev/null || true
                systemctl disable "$SERVICE_NAME" 2>/dev/null || true
                
                # 删除服务文件
                echo -e "${GREEN}2. 删除服务文件...${NC}"
                rm -f "$SERVICE_FILE"
                systemctl daemon-reload
                
                # 删除安装目录（保留配置文件）
                echo -e "${GREEN}3. 删除程序文件...${NC}"
                if [ -d "$INSTALL_DIR" ]; then
                    # 备份配置文件
                    if [ -f "$CONFIG_FILE" ]; then
                        BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d%H%M%S)"
                        cp "$CONFIG_FILE" "$BACKUP_FILE"
                        echo -e "${YELLOW}配置文件已备份到: $BACKUP_FILE${NC}"
                    fi
                    # 删除除配置文件外的其他文件
                    find "$INSTALL_DIR" -type f ! -name "*.json" -delete 2>/dev/null || true
                    find "$INSTALL_DIR" -type d -empty -delete 2>/dev/null || true
                fi
                
                # 删除 kk 命令（可选）
                echo -e "${GREEN}4. 删除控制台命令...${NC}"
                read -p "是否删除 kk 命令？(y/N): " delete_kk
                if [[ "$delete_kk" =~ ^[Yy]$ ]]; then
                    rm -f /usr/bin/kk
                    echo -e "${YELLOW}kk 命令已删除${NC}"
                else
                    echo -e "${YELLOW}kk 命令保留${NC}"
                fi
                
                echo -e "${GREEN}✅ 卸载完成！${NC}"
                echo -e "${YELLOW}注意: 配置文件保留在 $CONFIG_FILE${NC}"
            else
                echo -e "${YELLOW}卸载已取消${NC}"
            fi
            read -p "按回车继续..."
            ;;
        0)
            echo -e "${CYAN}>>> 退出控制台${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}✗ 无效选择${NC}"
            sleep 1
            ;;
    esac
done