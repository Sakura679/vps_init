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

#### 创建缺失文件（若系统中缺失则使用下方命令）
```
mkdir -p /run/openrc
touch /run/openrc/softlevel
```

#### 网络优化
设置MTU：
```
ip link set dev eth0 mtu 1480

写入脚本，开机自动设置放丢失
cat > /etc/local.d/mtu.start <<'EOF'
#!/bin/sh
ip link set dev eth0 mtu 1480
EOF
启动
chmod +x /etc/local.d/mtu.start
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
脚本赋权：
chmod +x /usr/local/bin/clean_resolv.sh
加入crond定时任务：
cat > /etc/crontabs/root <<'EOF'
*/30 * * * * /usr/local/bin/clean_resolv.sh
EOF
启动：
rc-service crond start
rc-update add crond
```

禁用ipv6：
```
cat > /etc/sysctl.conf <<'EOF'
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF

sysctl -p
```








