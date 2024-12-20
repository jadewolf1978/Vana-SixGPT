#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 语言选择
LANGUAGE="ZH"

# 消息定义
M_WELCOME="欢迎使用 SixGPT Miner 管理脚本"
M_CHECKING_SYSTEM="正在检查系统环境..."
M_CHECKING_GPU="正在检查 GPU 设备..."
M_DETECTED_GPU="检测到 GPU："
M_NO_GPU="未检测到 GPU 设备"
M_CHECKING_CPU="正在检查 CPU 信息..."
M_DETECTED_CPU="检测到 CPU："
M_CHECKING_RAM="正在检查内存信息..."
M_TOTAL_RAM="总内存："
M_AVAILABLE_RAM="可用内存："

# 安装 Docker 函数
install_docker() {
    echo -e "${YELLOW}正在安装 Docker...${NC}"
    case $OS in
        "Ubuntu")
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        "Debian GNU/Linux")
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        "CentOS Linux")
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        *)
            echo -e "${RED}不支持的操作系统: $OS${NC}"
            echo "请手动安装 Docker: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac

    sudo usermod -aG docker $USER
    echo -e "${GREEN}Docker 安装完成！${NC}"
    echo -e "${YELLOW}请注意：您可能需要重新登录以使用 Docker 而无需 sudo${NC}"
}

# 检查系统环境
check_system() {
    echo -e "${YELLOW}$M_CHECKING_SYSTEM${NC}"
    
    # 检查 CPU
    echo -e "${YELLOW}$M_CHECKING_CPU${NC}"
    if command -v lscpu &> /dev/null; then
        CPU_INFO=$(lscpu | grep "Model name" | cut -d ":" -f2 | xargs)
        echo -e "${GREEN}$M_DETECTED_CPU $CPU_INFO${NC}"
    fi

    # 检查内存
    echo -e "${YELLOW}$M_CHECKING_RAM${NC}"
    if command -v free &> /dev/null; then
        TOTAL_MEM=$(free -h | awk '/^Mem:/ {print $2}')
        AVAIL_MEM=$(free -h | awk '/^Mem:/ {print $7}')
        echo -e "${GREEN}$M_TOTAL_RAM $TOTAL_MEM${NC}"
        echo -e "${GREEN}$M_AVAILABLE_RAM $AVAIL_MEM${NC}"
    fi

    # 检查 GPU
    echo -e "${YELLOW}$M_CHECKING_GPU${NC}"
    if command -v nvidia-smi &> /dev/null; then
        GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader)
        echo -e "${GREEN}$M_DETECTED_GPU $GPU_INFO${NC}"
    elif command -v rocm-smi &> /dev/null; then
        GPU_INFO=$(rocm-smi --showproductname | grep "GPU" | head -n1)
        echo -e "${GREEN}$M_DETECTED_GPU $GPU_INFO${NC}"
    else
        echo -e "${YELLOW}$M_NO_GPU${NC}"
    fi
}

# 检查并安装 Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}未检测到 Docker，开始安装...${NC}"
        install_docker
    else
        echo -e "${GREEN}检测到 Docker 已安装${NC}"
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}未检测到 Docker Compose，开始安装...${NC}"
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo -e "${GREEN}检测到 Docker Compose 已安装${NC}"
    fi

    if ! systemctl is-active --quiet docker; then
        echo -e "${YELLOW}启动 Docker 服务...${NC}"
        sudo systemctl start docker
    fi
}

# 安装 SixGPT Miner
install_miner() {
    echo -e "${YELLOW}请输入您的 Vana 钱包私钥 (以0x开头):${NC}"
    read -p "> " VANA_PRIVATE_KEY

    if [[ ! $VANA_PRIVATE_KEY =~ ^0x[a-fA-F0-9]{64}$ ]]; then
        echo -e "${RED}错误: 无效的私钥格式！${NC}"
        exit 1
    fi

    echo -e "${YELLOW}正在下载配置文件...${NC}"
    curl -s -o docker-compose.yml https://raw.githubusercontent.com/sixgpt/miner/main/docker-compose.yml
    curl -s -o run_sixgpt.sh https://raw.githubusercontent.com/sixgpt/miner/main/run_sixgpt.sh
    chmod +x run_sixgpt.sh

    echo -e "${YELLOW}创建环境配置文件...${NC}"
    cat > .env << EOF
VANA_PRIVATE_KEY=$VANA_PRIVATE_KEY
VANA_NETWORK=moksha
OLLAMA_API_URL=http://ollama:11434/api
EOF

    echo -e "${GREEN}安装完成！${NC}"
}

# 启动服务
start_service() {
    echo -e "${YELLOW}启动 Docker 服务...${NC}"
    docker-compose up -d
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}=== 启动成功！===${NC}"
        echo -e "${YELLOW}请确保：${NC}"
        echo "1. 钱包中有至少 0.1 VANA"
        echo "2. 已在 sixgpt.xyz 上登录钱包"
        echo -e "${YELLOW}服务启动后，请等待约 1-2 分钟让系统初始化${NC}"
    else
        echo -e "${RED}启动失败，请检查错误信息${NC}"
    fi
}

# 查看日志
view_logs() {
    echo -e "${YELLOW}正在查看日志...按 Ctrl+C 退出${NC}"
    docker-compose logs -f
}

# 重启服务
restart_service() {
    echo -e "${YELLOW}正在重启服务...${NC}"
    docker-compose restart
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}重启成功！${NC}"
    else
        echo -e "${RED}重启失败，请检查错误信息${NC}"
    fi
}

# 清理服务
cleanup_service() {
    echo -e "${YELLOW}警告：这将删除所有容器和镜像！${NC}"
    read -p "确定要继续吗？(y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}正在清理...${NC}"
        docker-compose down --rmi all
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}清理完成！${NC}"
        else
            echo -e "${RED}清理失败，请检查错误信息${NC}"
        fi
    fi
}

# 显示菜单
show_menu() {
    clear
    echo -e "${GREEN}=== SixGPT Miner 管理脚本 ===${NC}"
    echo -e "${GREEN}功能菜单：${NC}"
    echo "1. 安装 SixGPT Miner"
    echo "2. 启动服务"
    echo "3. 查看日志"
    echo "4. 重启服务"
    echo "5. 清理服务"
    echo "6. 检查系统环境"
    echo "0. 退出"
    echo
    read -p "请选择操作 [0-6]: " choice
}

# 检测系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VERSION=$VERSION_ID
else
    echo -e "${RED}无法检测操作系统类型${NC}"
    exit 1
fi

# 显示欢迎信息
echo -e "${GREEN}$M_WELCOME${NC}"
echo -e "${YELLOW}系统信息：$OS $VERSION${NC}"
echo

# 主循环
while true; do
    show_menu
    case $choice in
        1)
            check_docker
            install_miner
            ;;
        2)
            start_service
            ;;
        3)
            view_logs
            ;;
        4)
            restart_service
            ;;
        5)
            cleanup_service
            ;;
        6)
            check_system
            ;;
        0)
            echo -e "${GREEN}感谢使用！再见！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效的选择，请重试${NC}"
            ;;
    esac
    echo
    read -p "按回车键继续..."
done
