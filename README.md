# SixGPT Miner 部署工具

这是一个用于部署和管理 SixGPT Miner 的中文脚本工具。

## 支持的系统
- Ubuntu
- Debian
- CentOS

## 前置要求
- 准备 Vana 钱包
  - 确保钱包中有至少 0.1 VANA=这点比较重要，目前领水一天领10VANA，但是只够1-2台电脑用。
  - 在 sixgpt.xyz 上完成钱包登录
    
- Vana领水地址，24小时一次
https://faucet.vana.com/moksha

## 快速开始

```bash
wget -O Vana-SixGPT.sh https://raw.githubusercontent.com/jadewolf1978/Vana-SixGPT/main/Vana-SixGPT-CN.sh && chmod +x Vana-SixGPT.sh && ./Vana-SixGPT.sh
```

## 功能特点
1. 完整的中文界面
2. 自动检测系统环境（CPU、内存、GPU）
3. 自动安装所需依赖（Docker、Docker Compose）
4. 提供完整的服务管理功能
   - 安装 SixGPT Miner
   - 启动服务
   - 查看日志
   - 重启服务
   - 清理服务
   - 检查系统环境

菜单界面

![image](https://github.com/user-attachments/assets/dc4e4a71-dd46-4de7-9a92-33822a5087c3)

运行界面

![e56a91d3d0f4ff58c4c33aa809c9ed4](https://github.com/user-attachments/assets/7e4b1b81-c8d8-446b-aa88-a6e619e208c7)

## 使用说明

### 主菜单选项
1. 安装 SixGPT Miner
2. 启动服务
3. 查看日志
4. 重启服务
5. 清理服务
6. 检查系统环境
0. 退出

### 注意事项
1. 请确保您有足够的系统权限（sudo）
2. 首次运行时，Docker 会下载必要的镜像，这可能需要一些时间
3. 请妥善保管您的钱包私钥，不要泄露给他人
4. 使用清理功能时请谨慎，该操作会删除所有相关的容器和镜像

## 问题排查
如果遇到问题，请检查：
1. 系统是否支持（Ubuntu/Debian/CentOS）
2. 是否有足够的系统权限
3. 网络连接是否正常
4. 使用"查看日志"功能检查具体错误信息

## 更新日志
- 2024-12-19
  - 优化系统环境检测
  - 改进错误处理和用户提示
  - 添加 GPU 检测支持（NVIDIA/AMD）

## 贡献
欢迎提交 Issue 和 Pull Request 来帮助改进这个项目。

## 许可证
MIT License
