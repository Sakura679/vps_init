#!/bin/bash

echo "======================================"
echo "BBR v3 完整诊断"
echo "======================================"
echo

# 1. 检查内核版本和 BBR 编译支持
echo "1️⃣ 内核信息:"
echo "---"
uname -a
echo
grep -i bbr /boot/config-$(uname -r) 2>/dev/null || echo "! 无法读取内核配置"
echo

# 2. 检查 BBR 模块加载状态
echo "2️⃣ BBR 模块状态:"
echo "---"
if lsmod | grep -q tcp_bbr; then
    echo "✅ BBR 模块已加载"
    lsmod | grep tcp_bbr
    echo
    # 检查模块详细信息
    if [ -d /sys/module/tcp_bbr ]; then
        echo "模块路径: /sys/module/tcp_bbr"
        ls -la /sys/module/tcp_bbr/
    fi
else
    echo "❌ BBR 模块未加载"
fi
echo

# 3. 检查当前拥塞控制算法
echo "3️⃣ 拥塞控制算法:"
echo "---"
echo "可用算法:"
cat /proc/sys/net/ipv4/tcp_available_congestion_control
echo
echo "当前算法:"
cat /proc/sys/net/ipv4/tcp_congestion_control
echo

# 4. 检查 fq qdisc
echo "4️⃣ 队列规则 (qdisc):"
echo "---"
if [ -f /proc/sys/net/core/default_qdisc ]; then
    echo "default_qdisc 支持: ✅"
    cat /proc/sys/net/core/default_qdisc
else
    echo "default_qdisc 支持: ❌"
fi
echo
echo "当前网络接口 qdisc:"
tc qdisc show 2>/dev/null || echo "! tc 命令不可用"
echo

# 5. 检查 ECN
echo "5️⃣ ECN 状态:"
echo "---"
cat /proc/sys/net/ipv4/tcp_ecn
echo "  (0=禁用, 1=启用, 2=完全支持)"
echo

# 6. 检查使用 BBR 的连接
echo "6️⃣ 使用 BBR 的连接:"
echo "---"
BBR_CONNS=$(ss -i 2>/dev/null | grep -c "bbr" || echo "0")
echo "BBR 连接数: $BBR_CONNS"
echo
if [ "$BBR_CONNS" -gt 0 ]; then
    echo "✅ 有连接正在使用 BBR"
    ss -i | grep bbr | head -5
else
    echo "⚠️ 当前没有 BBR 连接（可能是因为没有活跃连接）"
fi
echo

# 7. 检查 sysctl 配置
echo "7️⃣ sysctl 配置:"
echo "---"
echo "BBR 相关配置:"
sysctl -a 2>/dev/null | grep -E "(tcp_congestion|default_qdisc|tcp_ecn)" | head -10
echo

# 8. 检查配置文件
echo "8️⃣ 配置文件:"
echo "---"
if [ -f /etc/sysctl.d/99-bbr-v3.conf ]; then
    echo "✅ 配置文件存在"
    echo "内容:"
    cat /etc/sysctl.d/99-bbr-v3.conf
else
    echo "❌ 配置文件不存在"
fi
echo

# 9. 检查内核参数
echo "9️⃣ 内核参数验证:"
echo "---"
echo "tcp_congestion_control = $(cat /proc/sys/net/ipv4/tcp_congestion_control)"
echo "tcp_available_congestion_control = $(cat /proc/sys/net/ipv4/tcp_available_congestion_control)"
echo

# 10. 性能测试
echo "🔟 性能指标:"
echo "---"
echo "TCP 统计:"
cat /proc/net/sockstat
echo

echo "======================================"
echo "诊断完成"
echo "======================================"
