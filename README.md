# vps_init
云服务器初始配置优化

### AP系统
#### 更换镜像源：
清华：
```
cat > /etc/apk/repositories <<'EOF'
https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/main
https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/community
EOF

apk update
```

阿里：
```
cat > /etc/apk/repositories <<'EOF'
https://mirrors.aliyun.com/alpine/v3.22/main/
https://mirrors.aliyun.com/alpine/v3.22/community/
EOF

apk update
```

#### 安装包管理器
```
apk update
apk add bash curl wget ca-certificates
```

#### 创建缺失文件（若系统中缺失则使用下方命令）
```
mkdir -p /run/openrc
touch /run/openrc/softlevel
```

#### 网络优化
设置MTU(非必要不设置)：
```
ip link set dev eth0 mtu 1480

写入脚本，开机自动设置放丢失
cat > /etc/local.d/mtu.start <<'EOF'
#!/bin/sh
ip link set dev eth0 mtu 1480
EOF

chmod +x /etc/local.d/mtu.start
rc-update add local
```

启用bbr：
```
检查bbr是否安装
lsmod | grep bbr

查看是否已启用
sysctl net.ipv4.tcp_congestion_control

启用bbr
cat > /etc/sysctl.conf <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

sysctl -p

开机启动脚本
cat > /etc/local.d/setup_bbr.start <<'EOF'
#!/bin/sh
sysctl -p
EOF

chmod +x /etc/local.d/setup_bbr.start
rc-update add local
```

修改DNS：
```
cat > /etc/resolv.conf <<'EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

文件上锁，防止系统自动还原
chattr +i /etc/resolv.conf
解锁
chattr -i /etc/resolv.conf

副作用--上锁后，系统更新DNS失败会生成文件副本，所以需要写个脚本定时清理
cat > /usr/local/bin/clean_resolv.sh <<'EOF'
#!/bin/sh
rm -f /etc/resolv.conf.*
EOF

chmod +x /usr/local/bin/clean_resolv.sh

加入crond定时任务：
cat >> /etc/crontabs/root <<'EOF'
*/30 * * * * /usr/local/bin/clean_resolv.sh
EOF

rc-service crond start
rc-update add crond
```

禁用ipv6：
```
cat >> /etc/sysctl.conf <<'EOF'
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF

sysctl -p

开机启动脚本
cat > /etc/local.d/setup_bbr.start <<'EOF'
#!/bin/sh
sysctl -p
EOF

chmod +x /etc/local.d/setup_bbr.start
rc-update add local
```








