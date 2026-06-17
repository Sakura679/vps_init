#!/bin/bash

set -e

echo "======================================"
echo "      Linux BBR 一键启用脚本"
echo "======================================"
echo

# 识别系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "无法识别系统"
    exit 1
fi

echo "检测到系统: $PRETTY_NAME"
echo

# 安装依赖
install_deps() {
    case "$OS" in
        debian|ubuntu)
            apt update -y
            apt install -y procps kmod
            ;;
        centos|rhel)
            yum install -y procps-ng kmod
            ;;
        rocky|almalinux|fedora)
            dnf install -y procps-ng kmod
            ;;
        alpine)
            apk update
            apk add procps util-linux
            ;;
        *)
            echo "不支持的系统: $OS"
            exit 1
            ;;
    esac
}

install_deps

echo
echo "当前内核版本:"
uname -r
echo

# 检查 BBR 支持
if sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -qw bbr; then
    echo "✔ 内核已支持 BBR"
else
    echo "✘ 当前内核未检测到 BBR"

    KERNEL_MAJOR=$(uname -r | cut -d. -f1)
    KERNEL_MINOR=$(uname -r | cut -d. -f2)

    if [ "$KERNEL_MAJOR" -lt 4 ] || { [ "$KERNEL_MAJOR" -eq 4 ] && [ "$KERNEL_MINOR" -lt 9 ]; }; then
        echo "内核版本过低（需要 >= 4.9）"
        exit 1
    fi

    echo "内核版本满足要求，但未检测到 BBR 模块"
    echo "可能是定制内核（常见于部分 VPS）"
    exit 1
fi

echo
echo "写入 sysctl 配置..."

# 防重复写入
grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf 2>/dev/null || \
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf

grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf 2>/dev/null || \
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

# Alpine 特殊处理（没有 sysctl -p 行为完全一致问题）
if command -v sysctl >/dev/null 2>&1; then
    sysctl -p >/dev/null 2>&1 || true
fi

echo
echo "验证结果:"
echo "--------------------------------------"

CONG=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")

if [ "$CONG" = "bbr" ]; then
    echo "✔ BBR 启用成功"
else
    echo "✘ BBR 启用失败"
    exit 1
fi

echo
echo "当前状态:"
sysctl net.ipv4.tcp_congestion_control 2>/dev/null || true
sysctl net.core.default_qdisc 2>/dev/null || true

echo
echo "可用拥塞控制:"
sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null || true

echo
echo "======================================"
echo "完成"
echo "======================================"
