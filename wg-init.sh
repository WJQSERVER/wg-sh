#!/bin/bash

# check root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# install packages
install() {
    if [ $# -eq 0 ]; then
        echo "ARGS NOT FOUND"
        return 1
    fi

    for package in "$@"; do
        if ! command -v "$package" &>/dev/null; then
            if command -v dnf &>/dev/null; then
                dnf -y update && dnf install -y "$package"
            elif command -v yum &>/dev/null; then
                yum -y update && yum -y install "$package"
            elif command -v apt &>/dev/null; then
                apt update -y && apt install -y "$package"
            elif command -v apk &>/dev/null; then
                apk update && apk add "$package"
            else
                echo "UNKNOWN PACKAGE MANAGER"
                return 1
            fi
        fi
    done

    return 0
}

language="en"

# i18n case menu
echo "Please select your language:"
echo "1. English"
echo "2. 简体中文"
read -p "Enter your choice: " language
case $language in
    1)
        echo "Language: English"
        language="en"
        ;;
    2)
        echo "Language: 简体中文"
        language="zh_CN"
        ;;
    *)
        echo "Invalid choice, using English"
        ;;
esac

# start wireguard installation
if [ "$language" = "en" ]; then
    echo "Installing Wireguard..."
elif [ "$language" = "zh_CN" ]; then
    echo "正在安装 Wireguard..."
fi

# install wireguard
install wireguard

# create wireguard directory
if [ "$language" = "en" ]; then
    echo "Creating Wireguard directory..."
elif [ "$language" = "zh_CN" ]; then
    echo "正在创建 Wireguard 目录..."
fi
mkdir -p /etc/wireguard/key
cd /etc/wireguard/key
umask 077

# generate private key
if [ "$language" = "en" ]; then
    echo "Generating private key..."
elif [ "$language" = "zh_CN" ]; then
    echo "正在生成私钥..."
fi
wg genkey > privatekey

# generate public key
if [ "$language" = "en" ]; then
    echo "Generating public key..."
elif [ "$language" = "zh_CN" ]; then
    echo "正在生成公钥..."
fi
wg pubkey < privatekey > publickey

# print public key
pubkey=$(cat publickey)
prikey=$(cat privatekey)
if [ "$language" = "en" ]; then
    echo "Your Public key is: ${pubkey}"
    echo "Your Private key is: ${prikey}"
elif [ "$language" = "zh_CN" ]; then
    echo "您的公钥是: ${pubkey}"
    echo "您的私钥是: ${prikey}"
fi

# create wireguard network
if [ "$language" = "en" ]; then
    read -p "Enter the name of your wireguard network(default: wg0): " network_name
elif [ "$language" = "zh_CN" ]; then
    read -p "请输入 Wireguard 网络名称(默认: wg0): " network_name
fi

if [ -z "$network_name" ]; then
    network_name="wg0"
    if [ "$language" = "en" ]; then
        echo "Using default network name: ${network_name}"
    elif [ "$language" = "zh_CN" ]; then
        echo "使用默认网络名称: ${network_name}"
    fi
fi

if [ "$language" = "en" ]; then
    read -p "Enter the IP address of your wireguard interface(default: 10.0.0.1/24): " ip_address
elif [ "$language" = "zh_CN" ]; then
    read -p "请输入 Wireguard 接口 IP 地址(默认: 10.0.0.1/24): " ip_address
fi

if [ -z "$ip_address" ]; then
    ip_address="10.0.0.1/24"
    if [ "$language" = "en" ]; then 
        echo "Using default IP address: ${ip_address}"
    elif [ "$language" = "zh_CN" ]; then
        echo "使用默认 IP 地址: ${ip_address}"
    fi
fi

# create wireguard interface
if [ "$language" = "en" ]; then
    echo "Creating Wireguard interface..."
elif [ "$language" = "zh_CN" ]; then
    echo "正在创建 Wireguard 接口..."
fi
ip link add dev ${network_name} type wireguard
ip addr add ${ip_address} dev ${network_name}

# set wireguard interface
if [ "$language" = "en" ]; then
    echo "Setting Wireguard interface..."
elif [ "$language" = "zh_CN" ]; then
    echo "正在设置 Wireguard 接口..."    
fi
wg set ${network_name} private-key /etc/wireguard/key/privatekey

# start wireguard network
if [ "$language" = "en" ]; then
    echo "Starting Wireguard network..."
elif [ "$language" = "zh_CN" ]; then
    echo "正在启动 Wireguard 网络..."
fi
ip link set dev ${network_name} up

# configure wireguard port
if [ "$language" = "en" ]; then
    read -p "Enter the port of your wireguard interface(default: 51820): " port
elif [ "$language" = "zh_CN" ]; then
    read -p "请输入 Wireguard 接口端口(默认: 51820): " port
fi

if [ -z "$port" ]; then
    port="51820"
    if [ "$language" = "en" ]; then
        echo "Using default port: ${port}"
    elif [ "$language" = "zh_CN" ]; then
        echo "使用默认端口: ${port}"    
    fi
fi

wg set ${network_name} listen-port ${port}

# save configuration
if [ "$language" = "en" ]; then
    echo "Saving Wireguard configuration..."
elif [ "$language" = "zh_CN" ]; then    
    echo "正在保存 Wireguard 配置..."
fi
touch /etc/wireguard/${network_name}.conf
wg-quick save ${network_name}

# restart&enable wireguard service
if [ "$language" = "en" ]; then
    echo "Restarting and enabling Wireguard service..."
elif [ "$language" = "zh_CN" ]; then
    echo "正在重启并启用 Wireguard 服务..."
fi
wg-quick down ${network_name}
wg-quick up ${network_name}
systemctl enable wg-quick@${network_name}.service

# print configuration
if [ "$language" = "en" ]; then
echo
echo
echo "Your Wireguard configuration:"
echo "Interface: ${network_name}"
echo "Address: ${ip_address}"
echo "Port: ${port}"
echo "Public key: ${pubkey}"
echo "Private key: ${prikey}"
elif [ "$language" = "zh_CN" ]; then
echo
echo
echo "您的 Wireguard 配置:"
echo "接口: ${network_name}"
echo "地址: ${ip_address}"
echo "端口: ${port}"
echo "公钥: ${pubkey}"
echo "私钥: ${prikey}"
fi

