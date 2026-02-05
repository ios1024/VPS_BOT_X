#!/bin/bash
# VPS 遥控器 (Sentinel-X) 安装向导
# 版本: V6.9 (集成全功能 kk 控制台)

# 定义颜色
GREEN='\033[0;32m'
SKY='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${SKY}==============================================${NC}"
echo -e "     VPS 遥控器 (Sentinel-X) 安装向导 V6.9     "
echo -e "${SKY}==============================================${NC}"
echo ""

# ✅ Root 权限检查
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}错误: 请使用 root 用户运行此脚本!${NC}"
   exit 1
fi

# ✅ 路径定义
SOURCE_DIR=$(cd $(dirname $0); pwd)
TARGET_DIR="/root/vps_bot-x"
CONFIG_FILE="/root/sentinel_config.json"

echo -e "${GREEN}>>> [1/6] 检查系统环境...${NC}"
export DEBIAN_FRONTEND=noninteractive

# Python 版本检查
if ! command -v python3 &> /dev/null; then
    apt update -y > /dev/null 2>&1
    apt install -y python3 python3-pip > /dev/null 2>&1
fi

echo -e "${GREEN}>>> [2/6] 正在安装系统依赖...${NC}"
apt update -y > /dev/null 2>&1
apt install -y curl nano git vnstat nethogs iptables net-tools jq > /dev/null 2>&1 # 增加了 jq 用于处理 JSON

# 配置 vnstat
systemctl enable vnstat > /dev/null 2>&1
systemctl restart vnstat > /dev/null 2>&1

echo -e "${GREEN}>>> [3/6] 同步代码...${NC}"
mkdir -p "$TARGET_DIR"

if [ -f "$SOURCE_DIR/main.py" ] && [ "$SOURCE_DIR" != "$TARGET_DIR" ]; then
    echo -e "${SKY}    本地同步...${NC}"
    cp -r "$SOURCE_DIR"/* "$TARGET_DIR/"
elif [ ! -f "$TARGET_DIR/main.py" ]; then
    echo -e "${SKY}    GitHub 克隆...${NC}"
    TEMP_DIR=$(mktemp -d)
    git clone --depth 1 https://github.com/MEILOI/VPS_BOT_X.git "$TEMP_DIR" > /dev/null 2>&1
    if [ -d "$TEMP_DIR/vps_bot-x" ]; then
        cp -r "$TEMP_DIR/vps_bot-x/"* "$TARGET_DIR/"
    else
        echo -e "${RED}错误: 拉取失败${NC}"; rm -rf "$TEMP_DIR"; exit 1
    fi
    rm -rf "$TEMP_DIR"
fi

# 安装依赖
pip3 install python-telegram-bot psutil requests netifaces schedule --break-system-packages > /dev/null 2>&1

echo -e "${GREEN}>>> [4/6] 配置初始化...${NC}"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}未检测到配置，开始引导...${NC}"
    read -p "Bot Token: " INPUT_TOKEN
    read -p "Admin ID: " INPUT_ID
    read -p "VPS 备注: " INPUT_NAME
    INPUT_NAME=${INPUT_NAME:-MyVPS}

    cat > "$CONFIG_FILE" <<EOF
{
  "bot_token": "${INPUT_TOKEN}",
  "admin_id": ${INPUT_ID},
  "server_remark": "${INPUT_NAME}",
  "ban_threshold": 5,
  "ban_duration": "permanent",
  "daily_report_times": ["08:00", "20:00"],
  "traffic_limit_gb": 1024,
  "billing_day": 1,
  "daily_warn_gb": 50,
  "traffic_daily_report": true,
  "backup_paths": ["${TARGET_DIR}"],
  "backup_exclude": ["*.log", "*.tmp", "__pycache__", "cache"],
  "auto_backup": {"mode": "off", "time": "03:00"}
}
EOF
fi

echo -e "${GREEN}>>> [5/6] 注册服务...${NC}"
cat > /etc/systemd/system/vpsbot.service <<EOF
[Unit]
Description=VPS Remote Controller Bot X
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${TARGET_DIR}
ExecStart=/usr/bin/python3 ${TARGET_DIR}/main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vpsbot > /dev/null 2>&1
systemctl restart vpsbot

echo -e "${GREEN}>>> [6/6] 安装全功能 'kk' 控制台...${NC}"

# 🔥🔥🔥 核心修改：写入全功能 kk 脚本 🔥🔥🔥
# 注意：这里使用 EOFKK (不带引号) 来注入变量，但要注意转义 $ 符号
cat > /usr/bin/kk <<'EOFKK'
#!/bin/bash
# VPS遥控器控制台 (全功能版)

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

CONFIG_FILE="/root/sentinel_config.json"
SERVICE_NAME="vpsbot"

# 辅助函数：更新 JSON
update_json() {
    local key="$1"
    local val="$2"
    # 使用 Python 安全更新 JSON
    python3 -c "import json; f='$CONFIG_FILE'; d=json.load(open(f)); d['$key']='$val'; json.dump(d, open(f,'w'), indent=2)"
}

while true; do
    clear
    # 状态检测
    if systemctl is-active --quiet vpsbot; then
        STATUS="${GREEN}● 运行中${NC}"
    else
        STATUS="${RED}● 已停止${NC}"
    fi

    # 获取当前配置用于显示
    if [ -f "$CONFIG_FILE" ]; then
        CUR_TOKEN=$(grep -o '"bot_token": *"[^"]*"' $CONFIG_FILE | cut -d'"' -f4 | cut -c 1-10)...
        CUR_ID=$(grep -o '"admin_id": *[0-9]*' $CONFIG_FILE | awk '{print $2}')
    else
        CUR_TOKEN="未配置"
        CUR_ID="未配置"
    fi

    echo -e "${CYAN}================================${NC}"
    echo -e "     VPS 遥控器-X 控制台 V6.9"
    echo -e "     状态: $STATUS"
    echo -e "${CYAN}================================${NC}"
    echo -e "  [1] 启动服务    [5] 编辑配置(Nano)"
    echo -e "  [2] 重启服务    [6] 强制更新代码"
    echo -e "  [3] 停止服务    [7] 修改 Bot Token"
    echo -e "  [4] 查看日志    [8] 修改 Admin ID"
    echo -e "  [0] 退出"
    echo -e "${CYAN}--------------------------------${NC}"
    echo -e "  当前 Token: ${YELLOW}$CUR_TOKEN${NC}"
    echo -e "  当前 Admin: ${YELLOW}$CUR_ID${NC}"
    echo -e "${CYAN}================================${NC}"
    
    read -p "请选择: " choice
    case $choice in
        1) systemctl start vpsbot; echo "启动中..."; sleep 1 ;;
        2) systemctl restart vpsbot; echo "重启中..."; sleep 1 ;;
        3) systemctl stop vpsbot; echo "停止中..."; sleep 1 ;;
        4) journalctl -u vpsbot -f -n 50 ;;
        5) nano $CONFIG_FILE ;;
        6) 
           echo "正在从 GitHub 强制拉取更新..."
           bash <(curl -fsSL https://raw.githubusercontent.com/MEILOI/VPS_BOT_X/main/vps_bot-x/install.sh)
           exit 0 # 更新后退出，因为 install.sh 会重新生成 kk
           ;;
        7) 
           read -p "输入新 Token: " new_t
           if [[ "$new_t" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
               update_json "bot_token" "$new_t"
               echo -e "${GREEN}Token 已更新，正在重启服务...${NC}"
               systemctl restart vpsbot
               sleep 2
           else
               echo -e "${RED}Token 格式错误！${NC}"; sleep 2
           fi
           ;;
        8)
           read -p "输入新 Admin ID: " new_id
           if [[ "$new_id" =~ ^[0-9]+$ ]]; then
               # 注意：Admin ID 是数字，Python 处理时需要转 int，这里简化处理，直接写
               # 更稳健的方法是用 sed 或 python，这里用 python
               python3 -c "import json; f='$CONFIG_FILE'; d=json.load(open(f)); d['admin_id']=$new_id; json.dump(d, open(f,'w'), indent=2)"
               echo -e "${GREEN}ID 已更新，正在重启服务...${NC}"
               systemctl restart vpsbot
               sleep 2
           else
               echo -e "${RED}ID 必须是纯数字！${NC}"; sleep 2
           fi
           ;;
        0) exit 0 ;;
        *) echo "无效选择" ;;
    esac
done
EOFKK

chmod +x /usr/bin/kk

echo -e "${GREEN}🎉 安装完成！全功能控制台已就绪。${NC}"
echo -e "${SKY}输入 'kk' 即可呼出高级管理面板${NC}"
