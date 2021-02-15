#!/bin/bash

blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}


# 笨笨的检测方法
if [[ $(command -v apt-get) ]]; then
  cmd="apt-get"
elif [[ $(command -v yum) ]]; then
  cmd="yum"
else
  green "哈哈……这个辣鸡脚本不支持你的系统。 (-_-)"
  green "备注: 仅支持 Ubuntu 16+ / Debian 8+ / CentOS 7+ 系统" && exit 1
fi

function first(){

$cmd update -y
$cmd install unzip curl -y

checkDocker=$(which docker)
if [ "$checkDocker" == "" ]; then
  green "docker未安装，开始安装docker"
  sleep 1s
  curl -sSL https://get.docker.com/ | sh
  systemctl start docker
  systemctl enable docker.service
  green "恭喜docker结束！！"
  sleep 1s
fi
}

function install(){
cd /root
wget https://raw.githubusercontent.com/hqhyco/xray_web_docker/main/xray_web_docker.zip
unzip xray_web_docker.zip
read -p "请输入你的域名(eg: abc.com): " domainName
uuid=$(cat /proc/sys/kernel/random/uuid)
docker run --rm -it -v /root/xray/ssl:/acme.sh --net=host neilpang/acme.sh --issue -d $domainName --standalone
sed -i "s/abc.com/$domainName/g" /root/xray/config.json
sed -i "s/048e0bf2-dd56-11e9-aa37-5600024c1d6a/$uuid/g" /root/xray/config.json
docker run -d --name xray --network host --restart=always -v /root/xray/config.json:/etc/xray/config.json -v /root/xray/ssl:/etc/ssl teddysun/xray
chmod u+x /root/caddy/caddy
/root/caddy/caddy start --config /root/caddy/caddy.json

cat > /etc/systemd/system/caddy.service <<EOF
[Unit]
Description=vnc
After=network-online.target

[Service]
Type=simple
ExecStart=/root/caddy/caddy start --config /root/caddy/caddy.json
Restart=always
User=root

[Install]
WantedBy=default.target
EOF

service caddy start
systemctl enable caddy
systemctl daemon-reload
cat <<-EOF >./info.txt
-----------------------------------------------
地址：${domainName}
端口：443
id：${uuid}
加密：none
流控：xtls-rprx-direct
别名：自定义
传输协议：tcp
伪装类型：none
底层传输：xtls
跳过证书验证：false
-----------------------------------------------
EOF
green "== 安装完成."

cat /root/info.txt
}

function remove(){
docker rm -f xray
systemctl disable caddy
service caddy stop
rm -rf /root/caddy
rm -rf /root/xray
rm /root/info.txt
rm /root/xray_web_docker.zip
rm /etc/systemd/system/caddy.service
}

start_menu(){
    clear
    green " ===================================="
    green " 介绍：xray+vless+tcp+xtls+网页伪装docker版 "
    green " 系统：Ubuntu 16+/Debian 8+/CentOS 7+"
    green " centos未测试，应该也可以"
    green " ===================================="
    echo
    green " 1. xray+vless+tcp+xtls+网页伪装"
    green " 2. 卸载"
    green " 3. 查看配置"
    blue " 0. 退出脚本"
    echo
    read -p "请输入数字:" num
    case "$num" in
    1)
    first
    install
    ;;
    2)
    remove
    ;;
    3)
    [[ -e "/root/info.txt" ]] && cat /root/info.txt || red "还未安装本程序"
    sleep 1s
    start_menu
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "请输入正确数字"
    sleep 1s
    start_menu
    ;;
    esac
}


start_menu
