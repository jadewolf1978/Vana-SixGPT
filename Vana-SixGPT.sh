#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== SixGPT Miner 一键部署脚本 ===${NC}"

# 检测系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VERSION=$VERSION_ID
else
    echo -e "${RED}无法检测操作系统类型${NC}"
    exit 1
fi

# 安装 Docker 函数
install_docker() {
    echo -e "${YELLOW}正在安装 Docker...${NC}"
    case $OS in
        "Ubuntu")
            # 更新包索引
            sudo apt-get update
            # 安装必要的包
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            # 添加 Docker 的官方 GPG 密钥
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            # 添加 Docker 仓库
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            # 更新包索引
            sudo apt-get update
            # 安装 Docker
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            # 安装 Docker Compose
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        "Debian GNU/Linux")
            # 更新包索引
            sudo apt-get update
            # 安装必要的包
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            # 添加 Docker 的官方 GPG 密钥
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            # 添加 Docker 仓库
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            # 更新包索引
            sudo apt-get update
            # 安装 Docker
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            # 安装 Docker Compose
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        "CentOS Linux")
            # 安装必要的包
            sudo yum install -y yum-utils
            # 添加 Docker 仓库
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            # 安装 Docker
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            # 启动 Docker
            sudo systemctl start docker
            # 设置开机启动
            sudo systemctl enable docker
            # 安装 Docker Compose
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        *)
            echo -e "${RED}不支持的操作系统: $OS${NC}"
            echo "请手动安装 Docker: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac

    # 将当前用户添加到 docker 组
    sudo usermod -aG docker $USER
    echo -e "${GREEN}Docker 安装完成！${NC}"
    echo -e "${YELLOW}请注意：您可能需要重新登录以使用 Docker 而无需 sudo${NC}"
}

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}未检测到 Docker，开始安装...${NC}"
    install_docker
else
    echo -e "${GREEN}检测到 Docker 已安装${NC}"
fi

# 检查 docker-compose 是否安装
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}未检测到 Docker Compose，开始安装...${NC}"
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo -e "${GREEN}检测到 Docker Compose 已安装${NC}"
fi

# 启动 Docker 服务
if ! systemctl is-active --quiet docker; then
    echo -e "${YELLOW}启动 Docker 服务...${NC}"
    sudo systemctl start docker
fi

echo -e "${YELLOW}请输入您的 Vana 钱包私钥 (以0x开头):${NC}"
read -p "> " VANA_PRIVATE_KEY

if [[ ! $VANA_PRIVATE_KEY =~ ^0x[a-fA-F0-9]{64}$ ]]; then
    echo -e "${RED}错误: 无效的私钥格式！${NC}"
    exit 1
fi

# 下载必要文件
echo -e "${YELLOW}正在下载配置文件...${NC}"
curl -s -o docker-compose.yml https://raw.githubusercontent.com/sixgpt/miner/main/docker-compose.yml
curl -s -o run_sixgpt.sh https://raw.githubusercontent.com/sixgpt/miner/main/run_sixgpt.sh

# 创建 .env 文件
echo -e "${YELLOW}创建环境配置文件...${NC}"
cat > .env << EOF
VANA_PRIVATE_KEY=$VANA_PRIVATE_KEY
VANA_NETWORK=moksha
OLLAMA_API_URL=http://ollama:11434/api
EOF

# 启动服务
echo -e "${YELLOW}启动 Docker 服务...${NC}"
docker-compose down 2>/dev/null
docker-compose up -d

if [ $? -eq 0 ]; then
    echo -e "${GREEN}=== 部署成功！===${NC}"
    echo -e "${YELLOW}请确保：${NC}"
    echo "1. 钱包中有至少 0.1 VANA"
    echo "2. 已在 sixgpt.xyz 上登录钱包"
    echo -e "\n${YELLOW}常用命令：${NC}"
    echo "- 查看日志：docker-compose logs -f"
    echo "- 停止服务：docker-compose down"
else
    echo -e "${RED}部署失败，请检查错误信息${NC}"
fi
