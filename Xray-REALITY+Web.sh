#!/bin/bash

#系统信息
# 指令集(amd64、x86、arm64、armv7等)
unset arch
# 系统发行版名称（ubuntu、debian、fedora、centos、oracle、rhel等）
unset distro
# 发行版基于(debian/rhel)
unset distro_like
# 系统版本
unset system_version
# 包管理器（apt/yum/dnf/microdnf）
unset pkg
# CPU线程数
unset nproc



# 安装配置（nginx、openssl、PHP、cloudreve、xray的安装版本、位置等信息）
nginx_version="nginx-1.25.1"
openssl_version="openssl-openssl-3.1.3"
nginx_prefix="/usr/local/nginx"
nginx_config="${nginx_prefix}/conf.d/xray.conf"
nginx_service="/etc/systemd/system/nginx.service"

php_version="php-8.2.8"
# 此处(php_prefix)请使用绝对路径(安装imagick时有影响)
php_prefix="/usr/local/php"
php_service="/etc/systemd/system/php-fpm.service"

cloudreve_version="3.8.3"

nextcloud_url="https://download.nextcloud.com/server/releases/nextcloud-27.0.0.tar.bz2"

xray_config="/usr/local/etc/xray/config.json"

# 临时目录
temp_dir="/temp_install_xray_reality_web"



# 安装信息（是否已经安装）
unset is_installed
unset xray_is_installed
unset nginx_is_installed
unset php_is_installed




# 配置信息
# 域名列表，带www(如果对应domain_config_list为2，则不带www，和true_domain_list相同)
unset domain_list
# 域名列表，不带www
unset true_domain_list
# 域名配置类型：1:带www，2:不带www
unset domain_config_list
# 域名伪装类型：1:cloudreve，2:nextcloud，3:重定向至pretend_redirect_list对应的域名
unset pretend_list
# 重定向至什么域名，-代表不重定向
unset pretend_redirect_list
unset pretend_redirect_index_list

# TCP(REALITY)：0 禁用；1 启用
unset protocol_1
# grpc： 0 禁用；1 VLESS；2 VMess
unset protocol_2
# WebSocket：0 禁用；1 VLESS；2 VMess
unset protocol_3

# TCP(REALITY) 的 uuid
unset xid_1
# TCP(REALITY) 的 公钥
unset reality_public_key
# TCP(REALITY) 的 私钥
unset reality_private_key

# grpc 的 uuid
unset xid_2
# grpc的serviceName
unset serviceName

# ws 的 uuid
unset xid_3
# ws的path
unset path




# 其它安装过程中的临时信息
# 现在有没有通过脚本启动swap
using_swap_now=0
# 在更新
update=0
# 在 install_update_xray_reality_web 函数中
in_install_update_xray_reality_web=0
script_url="https://github.com/bluejerry2021/Xray-script/raw/main/Xray-REALITY+Web.sh"

#功能性函数：
#定义几个颜色
purple()                           #紫
{
    echo -e "\\033[35;1m${*}\\033[0m"
}
tyblue()                           #天依蓝
{
    echo -e "\\033[36;1m${*}\\033[0m"
}
green()                            #绿
{
    echo -e "\\033[32;1m${*}\\033[0m"
}
yellow()                           #黄
{
    echo -e "\\033[33;1m${*}\\033[0m"
}
red()                              #红
{
    echo -e "\\033[31;1m${*}\\033[0m"
}
blue()                             #蓝
{
    echo -e "\\033[34;1m${*}\\033[0m"
}
# 使用英文运行命令
english_run()
{
    local command
    command="$(type -P "$1")"
    if [ -z "${command}" ]; then
        env -i LANG="C.UTF-8" "$@"
    else
        shift
        env -i LANG="C.UTF-8" "${command}" "$@"
    fi
    return $?
}
#版本比较函数
version_ge()
{
    if [[ "$1" =~ $'\n' ]] || [[ "$2" =~ $'\n' ]]; then
        red "版本比较输入包含换行符！"
        report_bug_exit
    fi
    test "$(sort -rV <<< "$1"$'\n'"$2" | head -n 1)" == "$1"
}
report_bug()
{
    green  "欢迎进行Bug report(https://github.com/kirin10000/Xray-script/issues)，感谢您的支持"
    yellow "按回车键继续或者Ctrl+c退出"
    read -rs
}
report_bug_exit()
{
    green  "欢迎进行Bug report(https://github.com/kirin10000/Xray-script/issues)，感谢您的支持"
    exit 1
}
#进入工作目录
enter_temp_dir()
{
    local temp_exit_code=0
    if ! rm -rf "$temp_dir"; then
        swapoff "${temp_dir}/swap"
        rm -rf "$temp_dir" || temp_exit_code=1
    fi
    mkdir "$temp_dir" || temp_exit_code=1
    cd "$temp_dir" || temp_exit_code=1
    if [ $temp_exit_code -eq 1 ]; then
        yellow "进入临时目录失败"
        report_bug_exit
    fi
}
check_temp_dir()
{
    if ! [[ -d "${temp_dir}" ]]; then
        red "异常行为：尚未创建临时目录！"
        report_bug_exit
    fi
}
ask_if()
{
    local choice=""
    while [ "$choice" != "y" ] && [ "$choice" != "n" ]
    do
        tyblue "$1"
        read -r choice
    done
    [ "$choice" == y ] && return 0
    return 1
}


check_base_command()
{
    hash -r
    local i
    local temp_command_list=('bash' 'sh' 'command' 'type' 'hash' 'install' 'true' 'false' 'exit' 'echo' 'test' 'sort' 'sed' 'awk' 'grep' 'cut' 'cd' 'rm' 'cp' 'mv' 'head' 'tail' 'uname' 'tr' 'md5sum' 'cat' 'find' 'wc' 'ls' 'mktemp' 'swapon' 'swapoff' 'mkswap' 'chmod' 'chown' 'chgrp' 'export' 'tar' 'gzip' 'mkdir' 'arch' 'uniq' 'dd' 'env' 'mapfile' 'nproc' 'sleep' 'read')
    for i in "${temp_command_list[@]}"
    do
        if ! command -V "${i}" > /dev/null; then
            red "命令\"${i}\"未找到"
            red "不是标准的Linux系统"
            exit 1
        fi
    done
    temp_command_list=('rm' 'mkdir' 'chmod' 'chown')
    for i in "${temp_command_list[@]}"
    do
        if [ -z "$(type -P "$i")" ]; then
            red "命令 $i 没有可执行文件"
            red "不支持的系统！"
            report_bug_exit
        fi
    done
}
check_sudo()
{
    if [ "$SUDO_GID" ] && [ "$SUDO_COMMAND" ] && [ "$SUDO_USER" ] && [ "$SUDO_UID" ]; then
        if [ "$SUDO_USER" = "root" ] && [ "$SUDO_UID" = "0" ]; then
            #it's root using sudo, no matter it's using sudo or not, just fine
            return 0
        fi
        if [ -n "$SUDO_COMMAND" ]; then
            #it's a normal user doing "sudo su", or `sudo -i` or `sudo -s`, or `sudo su acmeuser1`
            echo "$SUDO_COMMAND" | grep -- "/bin/su\$" >/dev/null 2>&1 || echo "$SUDO_COMMAND" | grep -- "/bin/su " >/dev/null 2>&1 || grep "^$SUDO_COMMAND\$" /etc/shells >/dev/null 2>&1
            return $?
        fi
        #otherwise
        return 1
    fi
    return 0
}
check_and_get_system_info()
{
    check_base_command
    if [ "$EUID" != "0" ]; then
        red "请用root用户运行此脚本！！"
        exit 1
    fi
    if ! check_sudo; then
        yellow "检测到正在使用sudo！"
        yellow "acme.sh不支持sudo，请使用root用户运行此脚本"
        tyblue "详情请见：https://github.com/acmesh-official/acme.sh/wiki/sudo"
        exit 1
    fi
    if [[ ! -f '/etc/os-release' ]]; then
        red "/etc/os-release文件不存在！"
        red "不支持的系统！"
        exit 1
    fi
    if ! [[ -d /run ]]; then
        red "/run 目录不存在！"
        red "不支持的系统！"
        exit 1
    fi
    if [[ -f /.dockerenv ]] || grep -q 'docker\|lxc' /proc/1/cgroup && [[ "$(type -P systemctl)" ]]; then
        true
    elif [[ -d /run/systemd/system ]] || grep -q systemd <(ls -l /sbin/init); then
        true
    else
        red "仅支持使用systemd的系统！"
        exit 1
    fi
    if [ -n "$(type -P apt)" ] || [ -n "$(type -P apt-get)" ]; then
        if [ -n "$(type -P dnf)" ] || [ -n "$(type -P microdnf)" ] || [ -n "$(type -P yum)" ]; then
            red "同时存在 apt/apt-get 和 dnf/microdnf/yum"
            red "不支持的系统！"
            exit 1
        fi
        distro_like="debian"
        if [ -z "$(type -P apt)" ]; then
            red "该系统仅支持apt-get，不支持apt"
            tyblue "可能系统版本太老"
            red "不支持的系统！"
            exit 1
        fi
        pkg="apt"
        if [ -z "$(type -P apt-mark)" ]; then
            red "apt-mark命令不存在！"
            red "不支持的系统！"
            exit 1
        fi
        if [ -z "$(type -P dpkg)" ]; then
            red "dpkg命令不存在！"
            red "不支持的系统！"
            exit 1
        fi
    elif [ -n "$(type -P dnf)" ] || [ -n "$(type -P microdnf)" ] || [ -n "$(type -P yum)" ]; then
        distro_like="rhel"
        if [ -n "$(type -P dnf)" ]; then
            pkg="dnf"
        elif [ -n "$(type -P microdnf)" ]; then
            pkg="microdnf"
        else
            pkg="yum"
        fi
        if [ -z "$(type -P rpm)" ]; then
            red "rpm命令不存在！"
            red "不支持的系统！"
            exit 1
        fi
        if ! "$pkg" --help | grep -q "\\-\\-setopt"; then
            red "$pkg 命令不支持 \\-\\-setopt 选项"
            red "不支持的系统！"
            exit 1
        fi
        if ! "$pkg" --help | grep -q "\\-\\-disablerepo"; then
            red "$pkg 命令不支持 \\-\\-disablerepo 选项"
            red "不支持的系统！"
            exit 1
        fi
        if ! "$pkg" --help | grep -q "\\-\\-enablerepo"; then
            red "$pkg 命令不支持 \\-\\-enablerepo 选项"
            red "不支持的系统！"
            exit 1
        fi
        if [ "$pkg" != "dnf" ]; then
            if rpm -q dnf > /dev/null 2>&1; then
                red "dnf 已安装但没有可执行文件！"
                report_bug_exit
            fi
            tyblue "缺少包管理器dnf，尝试安装。。。"
            install_dependencies dnf
            check_and_get_system_info
            return
        fi
    else
        red "apt/apt-get/dnf/microdnf/yum命令均不存在！"
        red "不支持的系统！"
        exit 1
    fi
    trim_str()
    {
        if [[ "${temp_str}" =~ '"' ]]; then
            if ! [[ "${temp_str}" =~ ^'"'.*'"'$ ]]; then
                red "获取os-release信息失败！"
                red "不支持的系统！"
                exit 1
            fi
            temp_str="${temp_str#*\"}"
            temp_str="${temp_str%\"*}"
        fi
    }
    local temp_str
    local id
    temp_str="$(grep '^[ '$'\t]*ID[ '$'\t]*=' /etc/os-release | cut -d = -f 2-)"
    trim_str
    id="${temp_str}"
    local name
    temp_str="$(grep '^[ '$'\t]*NAME[ '$'\t]*=' /etc/os-release | cut -d = -f 2-)"
    trim_str
    name="${temp_str}"
    if [ -z "$id" ] || [ -z "$name" ]; then
        red "获取os-release信息失败！"
        red "不支持的系统！"
        exit 1
    fi
    while :
    do
        if grep -qiw ubuntu <<< "$id"; then
            if grep -qiw ubuntu <<< "$name" && [ "$distro_like" == "debian" ]; then
                distro="ubuntu"
                break
            fi
        elif grep -qiw debian <<< "$id"; then
            if grep -qiw debian <<< "$name" && [ "$distro_like" == "debian" ]; then
                distro="debian"
                break
            fi
        elif grep -qiw fedora <<< "$id"; then
            if grep -qiw fedora <<< "$name" && [ "$distro_like" == "rhel" ]; then
                distro="fedora"
                break
            fi
        elif grep -qiw centos <<< "$id"; then
            if grep -qiw centos <<< "$name" && [ "$distro_like" == "rhel" ]; then
                if grep -qiw stream <<< "$name"; then
                    distro="centos-stream"
                else
                    distro="centos"
                fi
                break
            fi
        elif grep -qiw oracle <<< "$name"; then
            if grep -qiw 'ol\|oracle' <<< "$id" && [ "$distro_like" == "rhel" ]; then
                distro="oracle"
                break
            fi
        elif grep -qiw rhel <<< "$id"; then
            if grep -qiw 'red hat\|redhat' <<< "$name" && [ "$distro_like" == "rhel" ]; then
                distro="rhel"
                break
            fi
        else
            distro="unknow"
            break
        fi
        red "os-release系统发行版信息id与name不符，或者发行版信息与软件包管理器不自洽！"
        red "获取系统发行版信息失败！"
        exit 1
    done
    temp_str="$(grep '^[ '$'\t'']*VERSION_ID[ '$'\t'']*=' /etc/os-release | cut -d = -f 2-)"
    trim_str
    system_version="${temp_str}"
    case "$(arch)" in
        'amd64' | 'x86_64')
            arch='amd64'
            ;;
        'armv5tel')
            arch='armv5'
            ;;
        'armv6l')
            arch='armv6'
            ;;
        'armv7' | 'armv7l')
            arch='armv7'
            ;;
        'armv8' | 'aarch64')
            arch='arm64'
            ;;
        *)
            arch=''
            ;;
    esac
    if ! nproc="$(nproc)" || ! [[ "$nproc" =~ ^(((-|)[1-9][0-9]*)|0)$ ]] || [ "$nproc" -le 0 ]; then
        red "获取处理器线程数失败"
        exit 1
    fi
    if [ "$distro" == "oracle" ] && ! version_ge "$system_version" 7; then
        red "系统版本过低！请使用 Oracle Linux 版本 >= 7 ，或其它发行版"
        exit 1
    elif [ "$distro" == "centos" ] && version_ge "$system_version" 8; then
        red "Centos 8已经弃用，请使用Centos Stream 8！"
        exit 1
    fi
    if [ -z "${BASH_SOURCE[0]}" ] || [[ "${BASH_SOURCE[0]}" =~ ^"/dev/fd/" ]]; then
        red "请以 \"bash 文件名\" 的形式运行脚本！"
        exit 1
    fi
}

clear_config()
{
    unset reality_private_key
    unset reality_public_key
    unset protocol_3
    protocol_3=0
    unset protocol_2
    protocol_2=0
    unset protocol_1
    protocol_1=0
    unset xid_3
    unset xid_2
    unset xid_1
    unset path
    unset serviceName
    # 域名配置
    unset domain_list
    unset true_domain_list
    unset domain_config_list
    unset pretend_list
    unset pretend_redirect_list
    unset pretend_redirect_index_list
    return 0
}
#获取配置信息
get_config_info()
{
    # 改进：移除json中的注释？
    local temp
    [ $is_installed -eq 0 ] && clear_config && return
    reality_private_key="$(grep '"privateKey"' "$xray_config" | cut -d : -f 2 | cut -d \" -f 2)"
    [ -z "$reality_private_key" ] && clear_config && return
    reality_public_key="$(grep '"reality_public_key"' "$xray_config" | cut -d : -f 2 | cut -d \" -f 2)"
    [ -z "$reality_public_key" ] && clear_config && return
    if grep -q '"network"[ '$'\t]*:[ '$'\t]*"ws"' "$xray_config"; then
        if [[ "$(grep -oE '"protocol"[ '$'\t'']*:[ '$'\t'']*"(vmess|vless)"' "$xray_config" | tail -n 1)" =~ '"vmess"' ]]; then
            protocol_3=2
        else
            protocol_3=1
        fi
        path="$(grep '"path"' "$xray_config" | tail -n 1 | cut -d : -f 2 | cut -d \" -f 2)"
        [ -z "$path" ] && clear_config && return
        xid_3="$(grep '"id"' "$xray_config" | tail -n 1 | cut -d : -f 2 | cut -d \" -f 2)"
        [ -z "$xid_3" ] && clear_config && return
    else
        protocol_3=0
    fi
    if grep -q '"network"[ '$'\t'']*:[ '$'\t'']*"grpc"' "$xray_config"; then
        if [ $protocol_3 -ne 0 ]; then
            temp=2
        else
            temp=1
        fi
        if [[ "$(grep -oE '"protocol"[ '$'\t]*:[ '$'\t]*"(vmess|vless)"' "$xray_config" | tail -n $temp | head -n 1)" =~ \"vmess\" ]]; then
            protocol_2=2
        else
            protocol_2=1
        fi
        serviceName="$(grep '"serviceName"' "$xray_config" | cut -d : -f 2 | cut -d \" -f 2)"
        [ -z "$serviceName" ] && clear_config && return
        xid_2="$(grep '"id"' "$xray_config" | tail -n $temp | head -n 1 | cut -d : -f 2 | cut -d \" -f 2)"
        [ -z "$xid_2" ] && clear_config && return
    else
        protocol_2=0
    fi
    temp=1
    [ $protocol_2 -ne 0 ] && ((temp++))
    [ $protocol_3 -ne 0 ] && ((temp++))
    if [ "$(grep -c '"clients"' "$xray_config")" -eq $temp ]; then
        protocol_1=1
        xid_1="$(grep '"id"' "$xray_config" | head -n 1 | cut -d : -f 2 | cut -d \" -f 2)"
        [ -z "$xid_1" ] && clear_config && return
    else
        protocol_1=0
    fi
    unset domain_list
    unset true_domain_list
    unset domain_config_list
    unset pretend_list
    unset pretend_redirect_list
    domain_list=($(grep "^#domain_list=" "$nginx_config" | cut -d = -f 2))
    [ ${#domain_list[@]} -le 0 ] && clear_config && return
    true_domain_list=($(grep "^#true_domain_list=" "$nginx_config" | cut -d = -f 2))
    [ ${#true_domain_list[@]} -ne ${#domain_list[@]} ] && clear_config && return
    domain_config_list=($(grep "^#domain_config_list=" "$nginx_config" | cut -d = -f 2))
    [ ${#domain_config_list[@]} -ne ${#domain_list[@]} ] && clear_config && return
    pretend_list=($(grep "^#pretend_list=" "$nginx_config" | cut -d = -f 2))
    [ ${#pretend_list[@]} -ne ${#domain_list[@]} ] && clear_config && return
    pretend_redirect_list=($(grep "^#pretend_redirect_list=" "$nginx_config" | cut -d = -f 2))
    [ ${#pretend_redirect_list[@]} -ne ${#domain_list[@]} ] && clear_config && return
    unset pretend_redirect_index_list
    local _redirect
    local i
    for _redirect in "${pretend_redirect_list[@]}"
    do
        if [ "$_redirect" == "-" ]; then
            pretend_redirect_index_list+=("")
            continue
        fi
        for ((i = 0; i < ${#domain_list[@]}; ++i))
        do
            if [ "$_redirect" == "${true_domain_list[$i]}" ]; then
                pretend_redirect_index_list+=("$i")
                break
            fi
        done
        clear_config
        return
    done
}
get_install_info()
{
    [ -f /usr/local/bin/xray ] && [ -f "$xray_config" ] && systemctl cat xray > /dev/null 2>&1 && xray_is_installed=1 || xray_is_installed=0
    [ -f "$nginx_config" ] && [ -f "$nginx_service" ] && [ -d "${nginx_prefix}/certs" ] && nginx_is_installed=1 || nginx_is_installed=0
    [ -f "${php_prefix}/php-fpm.service.default" ] && [ -f "$php_service" ] && php_is_installed=1 || php_is_installed=0
    [ $xray_is_installed -eq 1 ] && [ $nginx_is_installed -eq 1 ] && is_installed=1 || is_installed=0
    get_config_info
}


#安装依赖
try_install_dependencies()
{
    if [ "$#" -le 0 ] || { [ "$#" -eq 1 ] && [ -z "$1" ]; }; then
        red "没有输入要安装的软件包！"
        report_bug_exit
    fi
    if [ "$distro_like" == "debian" ]; then
        if apt -y --no-install-recommends -o Dpkg::Options::="--force-confnew" install "$@"; then
            return 0
        fi
        apt update
        if apt -y --no-install-recommends -o Dpkg::Options::="--force-confnew" install "$@"; then
            return 0
        fi
        apt update
        apt -y -f --no-install-recommends -o Dpkg::Options::="--force-confnew" install
        if apt -y --no-install-recommends -o Dpkg::Options::="--force-confnew" install "$@"; then
            return 0
        fi
    else
        # yum 安装多个软件包时，若其中某些软件包不存在，不会报错
        if [ "$pkg" == "yum" ] && [ "$#" -gt 1 ]; then
            red "异常行为：yum install 多个包"
            report_bug_exit
        fi
        gen_enablerepo_str()
        {
            if "$pkg" --help | grep -q "\\-\\-enablerepo="; then
                enablerepo_str=("--enablerepo=$1")
            else
                enablerepo_str=("--enablerepo" "$1")
            fi
        }
        gen_disablerepo_str()
        {
            if "$pkg" --help | grep -q "\\-\\-disablerepo="; then
                disablerepo_str=("--disablerepo=$1")
            else
                disablerepo_str=("--disablerepo" "$1")
            fi
        }
        local no_install_recommends
        local enablerepo_str
        local disablerepo_str
        if "$pkg" --help | grep -q "\\-\\-setopt="; then
            no_install_recommends=("--setopt=install_weak_deps=0")
        else
            no_install_recommends=("--setopt" "install_weak_deps=0")
        fi
        if "$pkg" -y "${no_install_recommends[@]}" install "$@"; then
            return 0
        fi
        local epel_repo
        if [ "$distro" == centos-stream ]; then
            epel_repo="epel,epel-next"
        elif [ "$distro" == oracle ]; then
            if version_ge "$system_version" 9; then
                epel_repo="ol9_developer_EPEL"
            elif version_ge "$system_version" 8; then
                epel_repo="ol8_developer_EPEL"
            elif version_ge "$system_version" 7; then
                epel_repo="ol7_developer_EPEL"
            fi
        else
            epel_repo="epel"
        fi
        gen_enablerepo_str "$epel_repo"
        if "$pkg" -y "${no_install_recommends[@]}" "${enablerepo_str[@]}" install "$@"; then
            return 0
        fi
        gen_enablerepo_str "$epel_repo,remi*"
        if "$pkg" -y "${no_install_recommends[@]}" "${enablerepo_str[@]}" install "$@"; then
            return 0
        fi
        gen_enablerepo_str "$epel_repo,powertools"
        if "$pkg" -y "${no_install_recommends[@]}" "${enablerepo_str[@]}" install "$@"; then
            return 0
        fi
        gen_enablerepo_str "$epel_repo,PowerTools"
        if "$pkg" -y "${no_install_recommends[@]}" "${enablerepo_str[@]}" install "$@"; then
            return 0
        fi
        gen_enablerepo_str "*"
        gen_disablerepo_str "*-debug,*-debuginfo,*-source"
        if "$pkg" -y "${no_install_recommends[@]}" "${enablerepo_str[@]}" "${disablerepo_str[@]}" install "$@"; then
            return 0
        fi
        if "$pkg" -y "${no_install_recommends[@]}" "${enablerepo_str[@]}" install "$@"; then
            return 0
        fi
    fi
    return 1
}
install_dependencies()
{
    if try_install_dependencies "$@"; then
        return 0
    fi
    yellow "依赖安装失败！！"
    report_bug
    return 1
}

# 检查并安装单个依赖：首先检查该依赖是否已经安装(dpkg/rpm)，如果该依赖已经安装，则不再安装(apt/dnf install)
# $1 : debian基系统
# $2 : redhat基系统
check_install_dependency()
{
    local output
    local package_name
    local ret=0
    if [ "$distro_like" == "debian" ]; then
        if english_run dpkg -s "$1" 2>/dev/null | grep -qi 'status[ '$'\t]*:[ '$'\t]*install[ '$'\t]*ok[ '$'\t]*installed[ '$'\t]*$'; then
            if ! output="$(english_run apt-mark manual "$1")"; then
                ret=1
            elif ! grep -qi 'set[ '$'\t]*to[ '$'\t]*manually[ '$'\t]*installed' <<< "$output"; then
                ret=1
            fi
            package_name="$1"
        else
            install_dependencies "$1"
        fi
    else
        if rpm -q "$2" > /dev/null 2>&1; then
            if [ "$pkg" != "dnf" ]; then
                red "异常行为：调用check_install_dependency包管理器不是dnf！"
                report_bug_exit
            fi
            dnf mark install "$2"
            ret=$?
            package_name="$2"
        else
            install_dependencies "$2"
        fi
    fi
    if [ $ret -ne 0 ]; then
        red "标记依赖 $package_name 手动安装失败！"
        report_bug
    fi
}
# 卸载软件包，对于debian基系统（使用apt），将会先检测软件包是否存在，请传入软件包使用正则表达式
remove_dependencies()
{
    pkg_exist()
    {
        local package
        local installed_packages
        installed_packages="$(english_run dpkg -l | grep '^[ '$'\t]*ii[ '$'\t]' | awk '{print $2}' | cut -d : -f 1)"
        for package in "$@"
        do
            if grep -q "$package" <<< "$installed_packages"; then
                exist_pkgs+=("$package")
            fi
        done
    }
    local ret
    if [ "$distro_like" == debian ]; then
        # 防止apt在卸载时自动下载替代软件包
        local exist_pkgs=()
        pkg_exist "$@"
        mv /etc/apt/sources.list /etc/apt/sources.list.bak
        mv /etc/apt/sources.list.d /etc/apt/sources.list.d.bak
        apt -y --allow-change-held-packages purge "${exist_pkgs[@]}"
        ret=$?
        mv /etc/apt/sources.list.bak /etc/apt/sources.list
        mv /etc/apt/sources.list.d.bak /etc/apt/sources.list.d
        if [ $ret -ne 0 ]; then
            if ! apt -y -f --no-install-recommends -o Dpkg::Options::="--force-confnew" install; then
                apt update
                apt -y -f --no-install-recommends -o Dpkg::Options::="--force-confnew" install
            fi
        fi
    else
        # dnf卸载不存在的包时一般返回0
        if [ "$pkg" != "dnf" ]; then
            red "异常行为：调用remove_dependencies包管理器不是dnf！"
            report_bug_exit
        fi
        dnf -y remove "$@"
        ret=$?
    fi
    if [ $ret -ne 0 ]; then
        red "卸载软件包 $* 失败！"
        report_bug
    fi
}







#升级系统组件
doupdate()
{
    updateSystem()
    {
        check_install_dependency ubuntu-release-upgrader-core ""
        echo -e "\\n\\n\\n"
        tyblue "------------------请选择升级系统版本--------------------"
        tyblue " 1. beta版(测试版)          当前版本号：23.10"
        tyblue " 2. release版(稳定版)       当前版本号：23.04"
        tyblue " 3. LTS版(长期支持版)       当前版本号：22.04"
        tyblue " 0. 不升级系统"
        tyblue "-------------------------注意事项-------------------------"
        yellow " 1.升级过程中遇到问话/对话框，如果不清楚，请选择yes/y/第一个选项"
        yellow " 2.升级系统可能需要15分钟或更久"
        yellow " 3.有的时候不能一次性更新到所选择的版本，可能要更新多次"
        yellow " 4.升级系统后以下配置可能会恢复系统默认配置："
        yellow "     ssh端口   ssh超时时间    bbr加速(恢复到关闭状态)"
        tyblue "----------------------------------------------------------"
        green  " 您现在的系统版本是：$system_version"
        tyblue "----------------------------------------------------------"
        echo
        choice=""
        while [[ ! "$choice" =~ ^(0|[1-9][0-9]*)$ ]] || ((choice>3))
        do
            read -rp "您的选择是：" choice
        done
        if [ "$choice" -ne 0 ]; then
            if ! [[ "$(grep -i '^[ '$'\t]*port[ '$'\t]' /etc/ssh/sshd_config | awk '{print $2}')" =~ ^("22"|)$ ]]; then
                red "检测到ssh端口号被修改"
                red "升级系统后ssh端口号可能恢复默认值(22)"
                yellow "按回车键继续。。。"
                read -rs
            fi
            if [ $in_install_update_xray_reality_web -eq 1 ]; then
                echo
                tyblue "提示：即将开始升级系统"
                yellow " 升级完系统后服务器将重启，重启后，请再次运行脚本完成 Xray-TLS+Web 剩余部分的安装/升级"
                yellow " 再次运行脚本时，重复之前选过的选项即可"
                echo
                sleep 2s
                yellow "按回车键以继续。。。"
                read -rs
                echo
            fi
        fi
        local i
        for ((i=0;i<2;i++))
        do
            sed -i '/^[ \t]*Prompt[ \t]*=/d' /etc/update-manager/release-upgrades
            echo 'Prompt=normal' >> /etc/update-manager/release-upgrades
            case "$choice" in
                1)
                    do-release-upgrade -d -m server
                    do-release-upgrade -d -m server
                    sed -i 's/Prompt=normal/Prompt=lts/' /etc/update-manager/release-upgrades
                    do-release-upgrade -d -m server
                    do-release-upgrade -d -m server
                    sed -i 's/Prompt=lts/Prompt=normal/' /etc/update-manager/release-upgrades
                    do-release-upgrade -p -m server
                    do-release-upgrade -p -m server
                    sed -i 's/Prompt=normal/Prompt=lts/' /etc/update-manager/release-upgrades
                    do-release-upgrade -p -m server
                    do-release-upgrade -p -m server
                    ;;
                2)
                    do-release-upgrade -m server
                    do-release-upgrade -m server
                    ;;
                3)
                    sed -i 's/Prompt=normal/Prompt=lts/' /etc/update-manager/release-upgrades
                    do-release-upgrade -m server
                    do-release-upgrade -m server
                    ;;
                0)
                    ;;
            esac
            apt -y --purge --allow-change-held-packages autoremove
            apt update
            apt -y --auto-remove --purge --no-install-recommends -o Dpkg::Options::="--force-confnew" --allow-change-held-packages full-upgrade
            apt -y --purge --allow-change-held-packages autoremove
            apt clean
            apt autoclean
        done
    }
    while :
    do
        echo -e "\\n\\n\\n"
        tyblue "-----------------------是否更新系统组件？-----------------------"
        green  " 1. 更新已安装软件，并升级系统 (仅Ubuntu可用)"
        green  " 2. 仅更新已安装软件"
        red    " 3. 不更新"
        if [ "$distro" == "ubuntu" ] && (($(free -b | sed -n 2p | awk '{print $2}') < 419430400)); then
            red "当前VPS内存不足400M，升级系统可能导致无法开机，请谨慎选择"
        fi
        echo
        choice=""
        while [ "$choice" != "1" ] && [ "$choice" != "2" ] && [ "$choice" != "3" ]
        do
            read -rp "您的选择是：" choice
        done
        if [ "$distro" == "ubuntu" ] || [ $choice -ne 1 ]; then
            break
        fi
        echo
        yellow " 更新系统仅支持Ubuntu！"
        sleep 3s
    done
    if [ "$choice" -eq 1 ]; then
        updateSystem
    elif [ "$choice" -eq 2 ]; then
        tyblue "-----------------------即将开始更新-----------------------"
        yellow " 更新过程中遇到问话/对话框，如果不清楚，请选择yes/y/第一个选项"
        yellow " 按回车键继续。。。"
        read -rs
        echo
        if [ "$distro_like" == "debian" ]; then
            apt -y --purge --allow-change-held-packages autoremove
            apt update
            apt -y --auto-remove --purge --no-install-recommends -o Dpkg::Options::="--force-confnew" --allow-change-held-packages full-upgrade
            apt -y --purge --allow-change-held-packages autoremove
            apt clean
            apt autoclean
        else
            dnf -y autoremove
            local no_install_recommends
            if dnf --help | grep -q "\\-\\-setopt="; then
                no_install_recommends=("--setopt=install_weak_deps=0")
            else
                no_install_recommends=("--setopt" "install_weak_deps=0")
            fi
            dnf "${no_install_recommends[@]}" -y upgrade
            dnf -y autoremove
            dnf clean all
        fi
    fi
}
#安装bbr
install_bbr()
{
    #输出：latest_kernel_version 和 your_kernel_version
    get_kernel_info()
    {
        green "正在获取最新版本内核版本号。。。。(20内秒未获取成功自动跳过)"
        your_kernel_version="$(uname -r | cut -d - -f 1)"
        while [ ${your_kernel_version##*.} -eq 0 ]
        do
            your_kernel_version=${your_kernel_version%.*}
        done
        if ! timeout 20 curl -Lo "temp_kernel_version" "https://kernel.ubuntu.com/~kernel-ppa/mainline/"; then
            latest_kernel_version="error"
            return 1
        fi
        local kernel_list=()
        local kernel_list_temp
        kernel_list_temp=($(awk -F'\"v' '/v[0-9]/{print $2}' "temp_kernel_version" | cut -d '"' -f1 | cut -d '/' -f1 | sort -rV))
        if [ ${#kernel_list_temp[@]} -le 1 ]; then
            latest_kernel_version="error"
            return 1
        fi
        local i2=0
        local i3
        local kernel_rc=""
        local kernel_list_temp2
        while ((i2<${#kernel_list_temp[@]}))
        do
            if [[ "${kernel_list_temp[$i2]}" =~ -rc(0|[1-9][0-9]*)$ ]] && [ "$kernel_rc" == "" ]; then
                kernel_list_temp2=("${kernel_list_temp[$i2]}")
                kernel_rc="${kernel_list_temp[$i2]%-*}"
                ((i2++))
            elif [[ "${kernel_list_temp[$i2]}" =~ -rc(0|[1-9][0-9]*)$ ]] && [ "${kernel_list_temp[$i2]%-*}" == "$kernel_rc" ]; then
                kernel_list_temp2+=("${kernel_list_temp[$i2]}")
                ((i2++))
            elif [[ "${kernel_list_temp[$i2]}" =~ -rc(0|[1-9][0-9]*)$ ]] && [ "${kernel_list_temp[$i2]%-*}" != "$kernel_rc" ]; then
                for((i3=0;i3<${#kernel_list_temp2[@]};i3++))
                do
                    kernel_list+=("${kernel_list_temp2[$i3]}")
                done
                kernel_rc=""
            elif [ -z "$kernel_rc" ] || version_ge "${kernel_list_temp[$i2]}" "$kernel_rc"; then
                kernel_list+=("${kernel_list_temp[$i2]}")
                ((i2++))
            else
                for((i3=0;i3<${#kernel_list_temp2[@]};i3++))
                do
                    kernel_list+=("${kernel_list_temp2[$i3]}")
                done
                kernel_rc=""
            fi
        done
        if [ -n "$kernel_rc" ]; then
            for((i3=0;i3<${#kernel_list_temp2[@]};i3++))
            do
                kernel_list+=("${kernel_list_temp2[$i3]}")
            done
        fi
        latest_kernel_version="${kernel_list[0]}"
        if [ "$distro_like" == "debian" ]; then
            local rc_version
            rc_version="$(uname -r | cut -d - -f 2)"
            if [[ $rc_version =~ rc ]]; then
                rc_version="${rc_version##*'rc'}"
                your_kernel_version="${your_kernel_version}-rc${rc_version}"
            fi
            uname -r | grep -q xanmod && your_kernel_version="${your_kernel_version}-xanmod"
        else
            latest_kernel_version="${latest_kernel_version%%-*}"
        fi
    }
    #卸载多余内核
    remove_other_kernel()
    {
        local exit_code=1
        if [ "$distro_like" == "debian" ]; then
            english_run dpkg --list > "temp_installed_list"
            local kernel_list_image
            kernel_list_image=($(awk '{print $2}' "temp_installed_list" | grep '^linux-image'))
            local kernel_list_modules
            kernel_list_modules=($(awk '{print $2}' "temp_installed_list" | grep '^linux-modules'))
            local kernel_now
            kernel_now="$(uname -r)"
            local ok_install=0
            for ((i=${#kernel_list_image[@]}-1;i>=0;i--))
            do
                if [[ "${kernel_list_image[$i]}" == *"$kernel_now"* ]]; then
                    unset 'kernel_list_image[$i]'
                    ((ok_install++))
                fi
            done
            if [ $ok_install -lt 1 ]; then
                red "未发现正在使用的内核，可能已经被卸载，请先重新启动"
                yellow "按回车键继续。。。"
                read -rs
                echo
                return 1
            fi
            for ((i=${#kernel_list_modules[@]}-1;i>=0;i--))
            do
                if [[ "${kernel_list_modules[$i]}" == *"$kernel_now"* ]]; then
                    unset 'kernel_list_modules[$i]'
                fi
            done
            if [ ${#kernel_list_modules[@]} -eq 0 ] && [ ${#kernel_list_image[@]} -eq 0 ]; then
                yellow "没有内核可卸载"
                return 0
            fi
            apt -y purge "${kernel_list_image[@]}" "${kernel_list_modules[@]}" && exit_code=0
            [ $exit_code -eq 1 ] && apt --no-install-recommends -y -f install
            apt-mark manual "^grub"
        else
            rpm -qa > "temp_installed_list"
            local kernel_list
            kernel_list=($(grep -E '^kernel(|-ml|-lt)-[0-9]' "temp_installed_list"))
            #local kernel_list_headers
            #kernel_list_headers=($(grep -E '^kernel(|-ml|-lt)-headers' "temp_installed_list"))
            local kernel_list_devel
            kernel_list_devel=($(grep -E '^kernel(|-ml|-lt)-devel' "temp_installed_list"))
            local kernel_list_modules
            kernel_list_modules=($(grep -E '^kernel(|-ml|-lt)-modules' "temp_installed_list"))
            local kernel_list_core
            kernel_list_core=($(grep -E '^kernel(|-ml|-lt)-core' "temp_installed_list"))
            local kernel_now
            kernel_now="$(uname -r)"
            local ok_install=0
            for ((i=${#kernel_list[@]}-1;i>=0;i--))
            do
                if [[ "${kernel_list[$i]}" == *"$kernel_now"* ]]; then
                    unset 'kernel_list[$i]'
                    ((ok_install++))
                fi
            done
            if [ $ok_install -lt 1 ]; then
                red "未发现正在使用的内核，可能已经被卸载，请先重新启动"
                yellow "按回车键继续。。。"
                read -rs
                echo
                return 1
            fi
            #for ((i=${#kernel_list_headers[@]}-1;i>=0;i--))
            #do
            #    if [[ "${kernel_list_headers[$i]}" =~ "$kernel_now" ]]; then
            #        unset 'kernel_list_headers[$i]'
            #    fi
            #done
            for ((i=${#kernel_list_devel[@]}-1;i>=0;i--))
            do
                if [[ "${kernel_list_devel[$i]}" == *"$kernel_now"* ]]; then
                    unset 'kernel_list_devel[$i]'
                fi
            done
            for ((i=${#kernel_list_modules[@]}-1;i>=0;i--))
            do
                if [[ "${kernel_list_modules[$i]}" == *"$kernel_now"* ]]; then
                    unset 'kernel_list_modules[$i]'
                fi
            done
            for ((i=${#kernel_list_core[@]}-1;i>=0;i--))
            do
                if [[ "${kernel_list_core[$i]}" == *"$kernel_now"* ]]; then
                    unset 'kernel_list_core[$i]'
                fi
            done
            #if [ ${#kernel_list[@]} -eq 0 ] && [ ${#kernel_list_headers[@]} -eq 0 ] && [ ${#kernel_list_devel[@]} -eq 0 ] && [ ${#kernel_list_modules[@]} -eq 0 ] && [ ${#kernel_list_core[@]} -eq 0 ]; then
            if [ ${#kernel_list[@]} -eq 0 ] && [ ${#kernel_list_devel[@]} -eq 0 ] && [ ${#kernel_list_modules[@]} -eq 0 ] && [ ${#kernel_list_core[@]} -eq 0 ]; then
                yellow "没有内核可卸载"
                return 0
            fi
            #$dnf -y remove "${kernel_list[@]}" "${kernel_list_headers[@]}" "${kernel_list_modules[@]}" "${kernel_list_core[@]}" "${kernel_list_devel[@]}" && exit_code=0
            dnf -y remove "${kernel_list[@]}" "${kernel_list_modules[@]}" "${kernel_list_core[@]}" "${kernel_list_devel[@]}" && exit_code=0
        fi
        if [ $exit_code -eq 0 ]; then
            green "卸载成功"
        else
            red "卸载失败！"
            yellow "按回车键继续或Ctrl+c退出"
            read -rs
            echo
            return 1
        fi
    }
    change_qdisc()
    {
        local list=('fq' 'fq_pie' 'cake' 'fq_codel')
        tyblue "---------------请选择你要使用的队列算法---------------"
        green  " 1.fq"
        green  " 2.fq_pie"
        tyblue " 3.cake"
        tyblue " 4.fq_codel"
        choice=""
        while [[ ! "$choice" =~ ^([1-9][0-9]*)$ ]] || ((choice>4))
        do
            read -rp "您的选择是：" choice
        done
        local qdisc="${list[$((choice-1))]}"
        local default_qdisc
        default_qdisc="$(sysctl net.core.default_qdisc | cut -d = -f 2 | awk '{print $1}')"
        sed -i '/^[ \t]*net.core.default_qdisc[ \t]*=/d' /etc/sysctl.conf
        echo "net.core.default_qdisc = $qdisc" >> /etc/sysctl.conf
        sysctl -p
        sleep 1s
        if [ "$(sysctl net.core.default_qdisc | cut -d = -f 2 | awk '{print $1}')" == "$qdisc" ]; then
            green "更换成功！"
        else
            red "更换失败，内核不支持"
            sed -i '/^[ \t]*net.core.default_qdisc[ \t]*=/d' /etc/sysctl.conf
            echo "net.core.default_qdisc = $default_qdisc" >> /etc/sysctl.conf
            return 1
        fi
    }
    enable_ecn()
    {
        if [[ ! -f /sys/module/tcp_bbr2/parameters/ecn_enable ]] || [ "$(sysctl net.ipv4.tcp_congestion_control | cut -d = -f 2 | awk '{print $1}')" != "bbr2" ]; then
            red "请先开启bbr2！"
            return 1
        fi
        if [ "$(cat /sys/module/tcp_bbr2/parameters/ecn_enable)" == "Y" ] && [ "$(sysctl net.ipv4.tcp_ecn | cut -d = -f 2 | awk '{print $1}')" == "1" ]; then
            green "bbr2_ECN 已启用！"
            tyblue "重启系统bbr2_ECN将自动关闭"
            return 0
        fi
        tyblue "提示：bbr2_ECN 会在系统重启后自动关闭"
        tyblue " 若重启系统，可以 运行脚本 -> 安装/更新bbr -> 启用bbr2_ECN 来重新启用bbr2_ECN"
        yellow "按回车键以继续。。。"
        read -rs
        echo
        echo Y > /sys/module/tcp_bbr2/parameters/ecn_enable
        sysctl net.ipv4.tcp_ecn=1
        sleep 1s
        if [ "$(cat /sys/module/tcp_bbr2/parameters/ecn_enable)" == "Y" ] && [ "$(sysctl net.ipv4.tcp_ecn | cut -d = -f 2 | awk '{print $1}')" == "1" ]; then
            green "bbr2_ECN 已启用"
            return 0
        else
            red "bbr2_ECN 启用失败"
            return 1
        fi
    }
    local your_kernel_version
    local latest_kernel_version
    get_kernel_info
    if ! grep -q "#This file has been edited by Xray-TLS-Web-setup-script" /etc/sysctl.conf; then
        echo >> /etc/sysctl.conf
        echo "#This file has been edited by Xray-TLS-Web-setup-script" >> /etc/sysctl.conf
    fi
    while :
    do
        echo -e "\\n\\n\\n"
        tyblue "------------------请选择要使用的bbr版本------------------"
        green  "  1. 安装最新稳定版内核并启用bbr  (推荐)"
        green  "  2. 安装最新xanmod内核并启用bbr  (推荐)"
        tyblue "  3. 安装最新xanmod内核并启用bbr2"
        tyblue "  4. 安装最新版内核(含测试版)并启用bbr"
        tyblue "  5. 启用bbr"
        tyblue "  6. 启用bbr2"
        tyblue "  7. 更换队列算法"
        tyblue "  8. 开启/关闭bbr2_ECN"
        tyblue "  9. 卸载多余内核"
        tyblue "  0. 退出bbr安装"
        tyblue "------------------关于安装bbr加速的说明------------------"
        tyblue " 1. bbr拥塞算法可以大幅提升网络速度，建议启用"
        tyblue " 2. bbr算法集成在内核中(从内核版本4.9开始)，升级内核可能提高bbr算法能力"
        tyblue "---------------------------------------------------------"
        tyblue " 当前内核版本：${your_kernel_version}"
        tyblue " 最新内核版本：${latest_kernel_version}"
        tyblue " 当前内核是否支持bbr："
        if version_ge "$your_kernel_version" 4.9; then
            green "     是"
        else
            red "     否，需升级内核"
        fi
        tyblue "   当前拥塞控制算法："
        local tcp_congestion_control
        tcp_congestion_control=$(sysctl net.ipv4.tcp_congestion_control | cut -d = -f 2 | awk '{print $1}')
        if [[ "$tcp_congestion_control" =~ bbr|nanqinlang|tsunami ]]; then
            if [[ "$tcp_congestion_control" =~ nanqinlang ]]; then
                tcp_congestion_control="${tcp_congestion_control} \\033[35m(暴力bbr魔改版)"
            elif [[ "$tcp_congestion_control" =~ tsunami ]]; then
                tcp_congestion_control="${tcp_congestion_control} \\033[35m(bbr魔改版)"
            fi
            green  "       ${tcp_congestion_control}"
        else
            tyblue "       ${tcp_congestion_control} \\033[31m(bbr未启用)"
        fi
        tyblue "   当前队列算法："
        green "       $(sysctl net.core.default_qdisc | cut -d = -f 2 | awk '{print $1}')"
        tyblue "   当前bbr2_ECN："
        if [ "$(cat /sys/module/tcp_bbr2/parameters/ecn_enable 2>/dev/null)" == "Y" ] && [ "$(sysctl net.ipv4.tcp_ecn | cut -d = -f 2 | awk '{print $1}')" == "1" ]; then
            green  "       已启用"
        else
            blue   "       未启用"
        fi
        echo
        local choice=""
        while [[ ! "$choice" =~ ^(0|[1-9][0-9]*)$ ]] || ((choice > 9))
        do
            read -rp "您的选择是：" choice
        done
        if ((1 <= choice && choice <= 4)); then
            if ((choice == 1 || choice == 4)) && [ "$distro_like" ==  "debian" ] && ! english_run dpkg-deb --help | grep -qw "zstd"; then
                red    "当前系统dpkg不支持zstd解压，不支持安装此内核！"
                green  "请更新系统，或选择使用其他系统(目前已知 Ubuntu、Debian 12+ 支持zstd解压)，或选择安装xanmod内核"
            elif ((choice == 2 || choice == 3)) && [ "$distro_like" ==  "rhel" ]; then
                red "xanmod内核仅支持Debian系的系统，如Ubuntu、Debian、deepin、UOS等"
            else
                if ((choice == 1 || choice == 4)) && [ "$distro_like" ==  "debian" ]; then
                    check_install_dependency linux-base ""
                    if ! version_ge "$(english_run dpkg --list | grep '^[ '$'\t]*ii[ '$'\t][ '$'\t]*linux-base[ '$'\t]' | awk '{print $3}')" "4.5ubuntu1~16.04.1"; then
                        install_dependencies linux-base
                        if ! version_ge "$(english_run dpkg --list | grep '^[ '$'\t]*ii[ '$'\t][ '$'\t]*linux-base[ '$'\t]' | awk '{print $3}')" "4.5ubuntu1~16.04.1"; then
                            if ! apt update; then
                                red "apt update出错"
                                report_bug
                            fi
                            install_dependencies linux-base
                        fi
                    fi
                fi
                if ((choice == 1 || choice == 4)) && [ "$distro_like" == "debian" ] && ! version_ge "$(english_run dpkg --list | grep '^[ '$'\t]*ii[ '$'\t][ '$'\t]*linux-base[ '$'\t]' | awk '{print $3}')" "4.5ubuntu1~16.04.1"; then
                    red    "当前系统版本过低，不支持安装此内核！"
                    green  "请使用新系统或选择安装xanmod内核"
                else
                    if [ $choice -eq 3 ]; then
                        local temp_bbr=bbr2
                    else
                        local temp_bbr=bbr
                    fi
                    if ! { [ "$(sysctl net.ipv4.tcp_congestion_control | cut -d = -f 2 | awk '{print $1}')" == "$temp_bbr" ] && [ "$(grep '^[ '$'\t]*net.ipv4.tcp_congestion_control[ '$'\t]*=' "/etc/sysctl.conf" | tail -n 1 | cut -d = -f 2 | awk '{print $1}')" == "$temp_bbr" ] && [ "$(sysctl net.core.default_qdisc | cut -d = -f 2 | awk '{print $1}')" == "$(grep '^[ '$'\t]*net.core.default_qdisc[ '$'\t]*=' "/etc/sysctl.conf" | tail -n 1 | cut -d = -f 2 | awk '{print $1}')" ]; }; then
                        sed -i '/^[ \t]*net.core.default_qdisc[ \t]*=/d' /etc/sysctl.conf
                        sed -i '/^[ \t]*net.ipv4.tcp_congestion_control[ \t]*=/d' /etc/sysctl.conf
                        echo 'net.core.default_qdisc = fq' >> /etc/sysctl.conf
                        echo "net.ipv4.tcp_congestion_control = $temp_bbr" >> /etc/sysctl.conf
                        sysctl -p
                    fi
                    if [ $in_install_update_xray_reality_web -eq 1 ]; then
                        echo
                        tyblue "提示："
                        yellow " 更换内核后服务器将重启，重启后，请再次运行脚本完成 Xray-TLS+Web 剩余部分的安装/升级"
                        yellow " 再次运行脚本时，重复之前选过的选项即可"
                        echo
                        sleep 2s
                        yellow "按回车键以继续。。。"
                        read -rs
                        echo
                    fi
                    local temp_kernel_sh_url
                    if [ $choice -eq 1 ]; then
                        temp_kernel_sh_url="https://github.com/bluejerry2021/update-kernel/raw/master/update-kernel-stable.sh"
                    elif [ $choice -eq 4 ]; then
                        temp_kernel_sh_url="https://github.com/bluejerry2021/update-kernel/raw/master/update-kernel.sh"
                    else
                        temp_kernel_sh_url="https://github.com/bluejerry2021/xanmod-install/raw/main/xanmod-install.sh"
                    fi
                    if ! curl -Lo kernel.sh "$temp_kernel_sh_url"; then
                        red    "获取内核安装脚本失败"
                        report_bug
                    fi
                    chmod +x kernel.sh
                    ./kernel.sh
                    if [ "$(sysctl net.ipv4.tcp_congestion_control | cut -d = -f 2 | awk '{print $1}')" == "$temp_bbr" ] && [ "$(sysctl net.core.default_qdisc | cut -d = -f 2 | awk '{print $1}')" == "$(grep '^[ '$'\t]*net.core.default_qdisc[ '$'\t]*=' "/etc/sysctl.conf" | tail -n 1 | cut -d = -f 2 | awk '{print $1}')" ]; then
                        green "--------------------$temp_bbr已安装--------------------"
                    else
                        red "开启$temp_bbr失败"
                        red "如果刚安装完内核，请先重启"
                        red "如果重启仍然无效，请尝试选项3"
                    fi
                fi
            fi
        elif [ $choice -eq 5 ]; then
            if [ "$(sysctl net.ipv4.tcp_congestion_control | cut -d = -f 2 | awk '{print $1}')" == "bbr" ] && [ "$(grep '^[ '$'\t]*net.ipv4.tcp_congestion_control[ '$'\t]*=' "/etc/sysctl.conf" | tail -n 1 | cut -d = -f 2 | awk '{print $1}')" == "bbr" ] && [ "$(sysctl net.core.default_qdisc | cut -d = -f 2 | awk '{print $1}')" == "$(grep '^[ '$'\t]*net.core.default_qdisc[ '$'\t]*=' "/etc/sysctl.conf" | tail -n 1 | cut -d = -f 2 | awk '{print $1}')" ]; then
                green "--------------------bbr已安装--------------------"
            else
                sed -i '/^[ \t]*net.core.default_qdisc[ \t]*=/d' /etc/sysctl.conf
                sed -i '/^[ \t]*net.ipv4.tcp_congestion_control[ \t]*=/d' /etc/sysctl.conf
                echo 'net.core.default_qdisc = fq' >> /etc/sysctl.conf
                echo 'net.ipv4.tcp_congestion_control = bbr' >> /etc/sysctl.conf
                sysctl -p
                sleep 1s
                if [ "$(sysctl net.ipv4.tcp_congestion_control | cut -d = -f 2 | awk '{print $1}')" == "bbr" ] && [ "$(sysctl net.core.default_qdisc | cut -d = -f 2 | awk '{print $1}')" == "fq" ]; then
                    green "--------------------bbr已安装--------------------"
                else
                    yellow "bbr启用失败，请尝试升级内核！"
                fi
            fi
        elif [ $choice -eq 6 ]; then
            if [ "$(sysctl net.ipv4.tcp_congestion_control | cut -d = -f 2 | awk '{print $1}')" == "bbr2" ] && [ "$(grep '^[ '$'\t]*net.ipv4.tcp_congestion_control[ '$'\t]*=' "/etc/sysctl.conf" | tail -n 1 | cut -d = -f 2 | awk '{print $1}')" == "bbr2" ] && [ "$(sysctl net.core.default_qdisc | cut -d = -f 2 | awk '{print $1}')" == "$(grep '^[ '$'\t]*net.core.default_qdisc[ '$'\t]*=' "/etc/sysctl.conf" | tail -n 1 | cut -d = -f 2 | awk '{print $1}')" ]; then
                green "--------------------bbr2已安装--------------------"
            else
                sed -i '/^[ \t]*net.core.default_qdisc[ \t]*=/d' /etc/sysctl.conf
                sed -i '/^[ \t]*net.ipv4.tcp_congestion_control[ \t]*=/d' /etc/sysctl.conf
                echo 'net.core.default_qdisc = fq' >> /etc/sysctl.conf
                echo 'net.ipv4.tcp_congestion_control = bbr2' >> /etc/sysctl.conf
                sysctl -p
                sleep 1s
                if [ "$(sysctl net.ipv4.tcp_congestion_control | cut -d = -f 2 | awk '{print $1}')" == "bbr2" ] && [ "$(sysctl net.core.default_qdisc | cut -d = -f 2 | awk '{print $1}')" == "fq" ]; then
                    green "--------------------bbr2已安装--------------------"
                else
                    red "启用bbr2失败"
                    yellow "可能是内核不支持"
                fi
            fi
        elif [ $choice -eq 7 ]; then
            change_qdisc
        elif [ $choice -eq 8 ]; then
            enable_ecn
        elif [ $choice -eq 9 ]; then
            tyblue " 该操作将会卸载除现在正在使用的内核外的其余内核"
            tyblue "    您正在使用的内核是：$(uname -r)"
            ask_if "是否继续？(y/n)" && remove_other_kernel
        else
            break
        fi
        sleep 3s
    done
}










#检查是否需要php
check_need_php()
{
    [ $is_installed -eq 0 ] && return 1
    local i
    for i in "${pretend_list[@]}"
    do
        [ "$i" -eq 2 ] && return 0
    done
    return 1
}
remove_xray()
{
    local script_src
    if { script_src="$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" || script_src="$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)"; } && [ -n "$script_src" ]; then
        bash <(echo "${script_src}") remove --purge
    fi
    {
        systemctl stop xray
        systemctl disable xray
    } &> /dev/null
    rm -rf /usr/local/bin/xray
    rm -rf /usr/local/etc/xray
    rm -rf /etc/systemd/system/xray.service
    rm -rf /etc/systemd/system/xray@.service
    rm -rf /var/log/xray
    systemctl daemon-reload
    xray_is_installed=0
    is_installed=0
}
disable_all_cloudreves()
{
    local all_cloudreves
    all_cloudreves=($(systemctl --type=service --all list-units 'cloudreve.*' | grep -o 'cloudreve\..*' | awk '{print $1}'))
    local service
    for service in "${all_cloudreves[@]}"
    do
        systemctl stop "$service"
        systemctl disable "$service" 2> /dev/null
    done
}
# 备份伪装网站，然后删除nginx和伪装网站
# 由于需要删除伪装网站，此函数同时会停止php-fpm，停止并禁用所有cloudreve服务
backup_remove_nginx_webs()
{
    check_temp_dir
    rm -rf "${temp_dir}/domain_backup"
    if ! mkdir "${temp_dir}/domain_backup"; then
        red "创建目录 ${temp_dir}/domain_backup 失败！"
        report_bug_exit
    fi
    systemctl stop php-fpm 2> /dev/null
    systemctl disable php-fpm 2> /dev/null
    disable_all_cloudreves
    systemctl stop nginx 2> /dev/null
    systemctl disable nginx 2> /dev/null
    local i
    for ((i = 0; i < ${#domain_list[@]}; ++i))
    do
        if ! mv "${nginx_prefix}/html/${true_domain_list[$i]}" "${temp_dir}/domain_backup/"; then
            red "备份伪装网站 ${domain_list[$i]} 失败！"
            report_bug
        fi
    done
    rm -f "${nginx_service}"
    systemctl daemon-reload
    rm -rf "${nginx_prefix}"
    nginx_is_installed=0
    is_installed=0
}
# 删除Nginx、伪装网站、域名证书
remove_nginx_webs()
{
    systemctl stop php-fpm 2> /dev/null
    systemctl disable php-fpm 2> /dev/null
    disable_all_cloudreves
    systemctl stop nginx 2> /dev/null
    systemctl disable nginx 2> /dev/null
    rm -f "$nginx_service"
    systemctl daemon-reload
    rm -rf "${nginx_prefix}"
    nginx_is_installed=0
    is_installed=0
}
restore_webs()
{
    local i
    for ((i = 0; i < ${#domain_list[@]}; ++i))
    do
        mv "${temp_dir}/domain_backup/${true_domain_list[$i]}" "${nginx_prefix}/html/"
    done
}
remove_php()
{
    systemctl stop php-fpm
    systemctl disable php-fpm
    rm -f "$php_service"
    systemctl daemon-reload
    rm -rf "${php_prefix}"
    php_is_installed=0
}
gen_reality_key()
{
    local lines
    mapfile -t lines <<<"$(/usr/local/bin/xray x25519)"
    if ! grep -qi private <<< "${lines[0]}" || ! grep -qi public <<< "${lines[1]}"; then
        red    "获取x25519密钥对出错"
        report_bug
    fi
    reality_private_key=$(echo "${lines[0]}" | cut -d ':' -f 2 | awk '{print $NF}')
    reality_public_key=$(echo "${lines[1]}" | cut -d ':' -f 2 | awk '{print $NF}')
}




















#检查Nginx是否已通过apt/dnf/yum安装
remove_nginx_system()
{
    if [[ ! -f /usr/lib/systemd/system/nginx.service ]] && [[ ! -f /lib/systemd/system/nginx.service ]]; then
        return 0
    fi
    red    "------------检测到Nginx已安装，并且会与此脚本冲突------------"
    yellow " 如果您不记得之前有安装过Nginx，那么可能是使用别的一键脚本时安装的"
    yellow " 建议使用纯净的系统运行此脚本"
    echo
    ! ask_if "是否尝试卸载？(y/n)" && exit 0
    if [ "$distro_like" == "debian" ]; then
        remove_dependencies '^nginx$' '^nginx-' '\-nginx$' '^.*-nginx-.*$' '^libnginx$' '^libnginx-' '\-libnginx$' '^.*-libnginx-.*$'
    else
        remove_dependencies 'nginx*'
    fi
    if [[ ! -f /usr/lib/systemd/system/nginx.service ]] && [[ ! -f /lib/systemd/system/nginx.service ]]; then
        return 0
    fi
    red "卸载失败！"
    report_bug
}
#检查PHP是否已通过apt/dnf/yum安装
remove_php_system()
{
    exists()
    {
        if [ $# -ne 1 ] || [ "$1" != "$expected" ]; then
            return 0
        fi
        return 1
    }
    local expected="/usr/lib/systemd/system/php*-fpm.service"
    if ! exists /usr/lib/systemd/system/php*-fpm.service && ! { expected="/lib/systemd/system/php*-fpm.service"; exists /lib/systemd/system/php*-fpm.service; }; then
        return 0
    fi
    red    "------------检测到PHP已安装，并且会与此脚本冲突------------"
    yellow " 如果您不记得之前有安装过PHP，那么可能是使用别的一键脚本时安装的"
    yellow " 建议使用纯净的系统运行此脚本"
    echo
    ! ask_if "是否尝试卸载？(y/n)" && exit 0
    if [ "$distro_like" == "debian" ]; then
        remove_dependencies '^php$' '^php-' '\-php$' '^.*-php-.*$'
    else
        remove_dependencies php '*-php-*' '*-php' 'php-*'
    fi
    expected="/usr/lib/systemd/system/php*-fpm.service"
    if ! exists /usr/lib/systemd/system/php*-fpm.service && ! { expected="/lib/systemd/system/php*-fpm.service"; exists /lib/systemd/system/php*-fpm.service; }; then
        return 0
    fi
    red "卸载失败！"
    report_bug
}

#检查SELinux
check_SELinux()
{
    turn_off_selinux()
    {
        if ! command -V setenforce >/dev/null 2>&1; then
            check_install_dependency selinux-utils libselinux-utils
        fi
        setenforce 0
        sed -i 's/^[ \t]*SELINUX[ \t]*=[ \t]*enforcing[ \t]*$/SELINUX=disabled/g' /etc/sysconfig/selinux
        sed -i 's/^[ \t]*SELINUX[ \t]*=[ \t]*enforcing[ \t]*$/SELINUX=disabled/g' /etc/selinux/config
    }
    if getenforce 2>/dev/null | grep -wqi Enforcing || grep -Eq '^[ '$'\t]*SELINUX[ '$'\t]*=[ '$'\t]*enforcing[ '$'\t]*$' /etc/sysconfig/selinux 2>/dev/null || grep -Eq '^[ '$'\t]*SELINUX[ '$'\t]*=[ '$'\t]*enforcing[ '$'\t]*$' /etc/selinux/config 2>/dev/null; then
        yellow "检测到SELinux已开启，脚本可能无法正常运行"
        if ask_if "尝试关闭SELinux?(y/n)"; then
            turn_off_selinux
        else
            exit 0
        fi
    fi
}

#检查TCP 80端口和443端口是否被占用
check_port()
{
    green "正在检查端口占用。。。"
    local xray_is_running=0
    local nginx_is_running=0
    systemctl -q is-active xray && xray_is_running=1
    systemctl -q is-active nginx && nginx_is_running=1
    [ $xray_is_running -ne 0 ] && systemctl stop xray
    [ $nginx_is_running -ne 0 ] && systemctl stop nginx
    local check_list=('80' '443')
    local i
    for i in "${check_list[@]}"
    do
        if ss -natl | awk '{print $4}'  | awk -F : '{print $NF}' | grep -E "^[0-9]+$" | grep -wq "${i}"; then
            red "TCP:${i}端口被占用！"
            yellow "请用 lsof -i:${i} 命令检查"
            exit 1
        fi
    done
    [ $xray_is_running -eq 1 ] && systemctl start xray
    [ $nginx_is_running -eq 1 ] && systemctl start nginx
    { [ $xray_is_running -eq 1 ] || [ $nginx_is_running -eq 1 ]; } && sleep 2s
}


#安装epel源
install_epel()
{
    if [ "$distro_like" == debian ]; then
        return
    fi
    local ret=0
    if [ "$distro" == fedora ]; then
        return
    elif [ "$distro" == centos-stream ]; then
        if version_ge "$system_version" 10; then
            ret=-1
        elif version_ge "$system_version" 9; then
            check_install_dependency "" dnf-plugins-core
            dnf config-manager --set-enabled crb || ret=-1
            install_dependencies epel-release epel-next-release
        elif version_ge "$system_version" 8; then
            check_install_dependency "" dnf-plugins-core
            dnf config-manager --set-enabled powertools || dnf config-manager --set-enabled PowerTools || ret=-1
            install_dependencies epel-release epel-next-release
        else
            ret=-1
        fi
    elif [ "$distro" == centos ]; then
        if version_ge "$system_version" 8; then
            ret=-1
        elif version_ge "$system_version" 7; then
            install_dependencies epel-release
        else
            ret=-1
        fi
    elif [ "$distro" == oracle ]; then
        if version_ge "$system_version" 10; then
            ret=-1
        elif version_ge "$system_version" 9; then
            install_dependencies oracle-epel-release-el9
        elif version_ge "$system_version" 8; then
            install_dependencies oracle-epel-release-el8
        elif version_ge "$system_version" 7; then
            install_dependencies oracle-epel-release-el7
        else
            ret=-1
        fi
    elif [ "$distro" == rhel ]; then
        if version_ge "$system_version" 10; then
            ret=-1
        elif version_ge "$system_version" 9; then
            subscription-manager repos --enable "codeready-builder-for-rhel-9-$(arch)-rpms" || ret=-1
            install_dependencies "https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm"
        elif version_ge "$system_version" 8; then
            subscription-manager repos --enable "codeready-builder-for-rhel-8-$(arch)-rpms" || ret=-1
            install_dependencies "https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
        elif version_ge "$system_version" 7; then
            subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms" --enable "rhel-ha-for-rhel-*-server-rpms" || ret=-1
            install_dependencies "https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
        else
            ret=-1
        fi
    else
        # 未知的操作系统
        if "$pkg" repolist epel | grep -q epel; then
            return
        fi
        install_dependencies epel-release
    fi

    if [ $ret -ne 0 ]; then
        yellow "epel源安装失败！！"
        report_bug
    fi
}
install_remi()
{
    if [ "$distro" == "fedora" ]; then
        install_dependencies "https://rpms.remirepo.net/fedora/remi-release-${system_version}.rpm"
    elif [ "$distro" == "centos-stream" ] || [ "$distro" == "oracle" ] || [ "$distro" == "rhel" ]; then
        if version_ge "$system_version" 9; then
            install_dependencies "https://rpms.remirepo.net/enterprise/remi-release-9.rpm"
        fi
    fi
}
update_script()
{
    if [ "$(cat "${BASH_SOURCE[0]}")" != "$(curl -L "${script_url}")" ]; then
        green "脚本可升级"
        if ask_if "是否升级脚本？(y/n)"; then
            if curl -Lo "${BASH_SOURCE[0]}" "${script_url}" || curl -Lo "${BASH_SOURCE[0]}" "${script_url}"; then
                green "脚本更新完成，请重新运行脚本！"
                exit 0
            else
                red "更新脚本失败！"
                exit 1
            fi
        fi
    else
        green "脚本已经是最新版本"
    fi
}

#配置sshd
check_ssh_timeout()
{
    if grep -q "#This file has been edited by Xray-REALITY-Web-setup-script" /etc/ssh/sshd_config; then
        return 0
    fi
    echo -e "\\n\\n\\n"
    tyblue "------------------------------------------"
    tyblue " 安装可能需要比较长的时间"
    tyblue " 如果中途断开连接将会很麻烦"
    tyblue " 设置ssh连接超时时间将有效降低断连可能性"
    echo
    ! ask_if "是否设置ssh连接超时时间？(y/n)" && return 0
    sed -i '/^[ \t]*ClientAliveInterval[ \t]/d' /etc/ssh/sshd_config
    sed -i '/^[ \t]*ClientAliveCountMax[ \t]/d' /etc/ssh/sshd_config
cat >> /etc/ssh/sshd_config << EOF

ClientAliveInterval 30
ClientAliveCountMax 60
#This file has been edited by Xray-REALITY-Web-setup-script
EOF
    if systemctl cat ssh > /dev/null 2>&1; then
        systemctl restart ssh
    else
        systemctl restart sshd
    fi
    green  "----------------------配置完成----------------------"
    tyblue " 请重新连接服务器以让配置生效"
    if [ $in_install_update_xray_reality_web -eq 1 ]; then
        yellow " 重新连接服务器后，请再次运行脚本完成剩余部分的安装/升级"
        yellow " 再次运行脚本时，重复之前选过的选项即可"
        yellow " 按回车键退出。。。。"
        read -rs
    fi
    exit 0
}

#读取xray_protocol配置
#不会生成密钥对
readProtocolConfig()
{
    echo -e "\\n\\n\\n"
    tyblue "---------------------请选择传输协议---------------------"
    tyblue " 1. TCP(REALITY)"
    tyblue " 2. gRPC"
    tyblue " 3. WebSocket"
    tyblue " 4. TCP(REALITY) + gRPC"
    tyblue " 5. TCP(REALITY) + WebSocket"
    tyblue " 6. gRPC + WebSocket"
    tyblue " 7. TCP(REALITY) + gRPC + WebSocket"
    yellow " 0. 无 (仅提供Web服务)"
    echo
    blue   " 注："
    blue   "   1. 如不使用CDN，请选择TCP(REALITY)"
    blue   "   2. gRPC和WebSocket支持通过CDN，关于两者的区别，详见：https://github.com/kirin10000/Xray-script#关于grpc与websocket"
    echo
    local choice=""
    while [[ ! "$choice" =~ ^(0|[1-9][0-9]*)$ ]] || ((choice>7))
    do
        read -rp "您的选择是：" choice
    done
    if [ "$choice" -eq 1 ] || [ "$choice" -eq 4 ] || [ "$choice" -eq 5 ] || [ "$choice" -eq 7 ]; then
        protocol_1=1
        if [ -z "$xid_1" ]; then
            xid_1="$(cat /proc/sys/kernel/random/uuid)"
        fi
    else
        protocol_1=0
        unset xid_1
    fi
    if [ "$choice" -eq 2 ] || [ "$choice" -eq 4 ] || [ "$choice" -eq 6 ] || [ "$choice" -eq 7 ]; then
        protocol_2=1
        if [ -z "$xid_2" ]; then
            xid_2="$(cat /proc/sys/kernel/random/uuid)"
        fi
        if [ -z "$serviceName" ]; then
            serviceName="$(head -c 20 /dev/urandom | md5sum | head -c 10)"
        fi
    else
        protocol_2=0
        unset xid_2
        unset serviceName
    fi
    if [ "$choice" -eq 3 ] || [ "$choice" -eq 5 ] || [ "$choice" -eq 6 ] || [ "$choice" -eq 7 ]; then
        protocol_3=1
        if [ -z "$xid_3" ]; then
            xid_3="$(cat /proc/sys/kernel/random/uuid)"
        fi
        if [ -z "$path" ]; then
            path="/$(head -c 20 /dev/urandom | md5sum | head -c 10)"
        fi
    else
        protocol_3=0
        unset xid_3
        unset path
    fi
    if [ $protocol_2 -eq 1 ]; then
        tyblue "-------------- 请选择使用gRPC传输的代理协议 --------------"
        tyblue " 1. VMess"
        tyblue " 2. VLESS"
        echo
        yellow " 注：使用VMess的好处是可以对CDN加密，若使用VLESS，CDN提供商可获取传输明文"
        echo
        choice=""
        while [[ ! "$choice" =~ ^([1-9][0-9]*)$ ]] || ((choice>2))
        do
            read -rp "您的选择是：" choice
        done
        [ "$choice" -eq 1 ] && protocol_2=2
    fi
    if [ $protocol_3 -eq 1 ]; then
        tyblue "-------------- 请选择使用WebSocket传输的代理协议 --------------"
        tyblue " 1. VMess"
        tyblue " 2. VLESS"
        echo
        yellow " 注：使用VMess的好处是可以对CDN加密，若使用VLESS，CDN提供商可获取传输明文"
        echo
        choice=""
        while [[ ! "$choice" =~ ^([1-9][0-9]*)$ ]] || ((choice>2))
        do
            read -rp "您的选择是：" choice
        done
        [ $choice -eq 1 ] && protocol_3=2
    fi
}

# 只会读取domain_list,domain_config_list,true_domain_list
select_domain()
{
    local i
    tyblue "----------------------- $1 -----------------------"
    for i in "${!domain_list[@]}"
    do
        if [ ${domain_config_list[$i]} -eq 1 ]; then
            tyblue " $((i+1)). ${domain_list[$i]} ${true_domain_list[$i]}"
        else
            tyblue " $((i+1)). ${domain_list[$i]}"
        fi
    done
    yellow " 0. 不选择"
    selected_domain_index=""
    while ! [[ "$selected_domain_index" =~ ^([1-9][0-9]*|0)$ ]] || [ $selected_domain_index -gt ${#domain_list[@]} ]
    do
        read -rp "你的选择是：" selected_domain_index
    done
    [ $selected_domain_index -eq 0 ] && return 1
    ((selected_domain_index--))
    return 0
}
#读取伪装类型
# 输入参数1： 域名index
# 输出pretend, pretend_redirect, pretend_redirect_index
# 不会读取pretend_list[index], pretend_rediretc_list[index], pretend_redirect_index_list[index]
readPretend()
{
    while :
    do
        echo -e "\\n\\n\\n"
        tyblue "------------------------------请选择伪装网站页面------------------------------"
        green  " 1. Cloudreve"
        purple "     国产开源个人网盘，轻巧，速度快，性能强"
        green  " 2. Nextcloud (需安装php)"
        purple "     全球热门的开源个人网盘，功能多，速度较慢；如尚未安装php，则需额外花费约20分钟时间安装php"
        green  " 3. 重定向至本服务器其他域名伪装网站"
        purple "     当这台服务器已经使用此脚本安装Xray-REALITY+Web，并且将要或已经配置了多个域名，则可使用此选项配置多个域名使用相同伪装网站后端（比如多个域名使用一个网盘后端，则多个域名的网盘内存放文件相同），可减少性能开销"
        echo
        green  " 若内存<1G 建议选择 Cloudreve"
        echo
        pretend=""
        pretend_redirect="-"
        pretend_redirect_index=""
        local selected_domain_index
        local selected
        while [[ "$pretend" != "1" && "$pretend" != "2" && "$pretend" != "3" ]]
        do
            read -rp "您的选择是：" pretend
        done
        if [ "$pretend" -eq 1 ]; then
            if [ -z "$arch" ]; then
                red "您的VPS指令集不支持Cloudreve！"
                yellow "Cloudreve仅支持 amd64(x86_64), arm64, armv7, armv6, armv5 !"
                sleep 3s
                continue
            fi
        elif [ "$pretend" -eq 2 ]; then
            if { { [ "$distro" == centos ] || [ "$distro" == centos-stream ] || [ "$distro" == oracle ] || [ "$distro" == rhel ]; } && ! version_ge "$system_version" "8"; } || { [ "$distro" == "fedora" ] && ! version_ge "$system_version" "32"; } || { [ "$distro" == "ubuntu" ] && ! version_ge "$system_version" "20.04"; } || { [ "$distro" == "debian" ] && ! version_ge "$system_version" 11; }; then
                red "系统版本过低，无法安装php！"
                echo
                tyblue "安装Nextcloud需要安装php"
                yellow "仅支持在以下版本系统下安装php："
                yellow " 1. Ubuntu 20.04+"
                yellow " 2. Debian 11+"
                yellow " 3. 其他以 Debian 11+ 为基的系统"
                yellow " 4. Red Hat Enterprise Linux 8+"
                yellow " 5. CentOS 8+"
                yellow " 6. Fedora 30+"
                yellow " 7. Oracle Linux 8+"
                yellow " 8. 其他以 Red Hat 8+ 为基的系统"
                sleep 3s
                continue
            elif [ "$distro" == unknow ]; then
                yellow "警告：未知的系统，可能导致php安装失败！"
                echo
                tyblue "安装Nextcloud需要安装php"
                yellow "仅支持在以下版本系统下安装php："
                yellow " 1. Ubuntu 20.04+"
                yellow " 2. Debian 11+"
                yellow " 3. 其他以 Debian 11+ 为基的系统"
                yellow " 4. Red Hat Enterprise Linux 8+"
                yellow " 5. CentOS 8+"
                yellow " 6. Fedora 30+"
                yellow " 7. Oracle Linux 8+"
                yellow " 8. 其他以 Red Hat 8+ 为基的系统"
                ! ask_if "确定选择吗？(y/n)" && continue
            fi
            if [ $php_is_installed -eq 0 ]; then
                tyblue "安装Nextcloud需要安装php"
                yellow "编译&&安装php可能需要额外消耗15-60分钟"
                yellow "php将占用一定系统资源，不建议内存<512M的机器使用"
                ! ask_if "确定选择吗？(y/n)" && continue
            fi
        elif [ "$pretend" -eq 3 ]; then
            if [ "${#domain_list[@]}" -eq 1 ]; then
                yellow "当前尚未安装Xray-REALITY+Web，不可选择重定向！"
                sleep 3s
                continue
            fi
            selected=0
            while :
            do
                if ! select_domain "请选择需要重定向的域名"; then
                    break
                fi
                if [ $selected_domain_index -eq $1 ]; then
                    yellow "选择重定向至自己，请重新选择！"
                    sleep 1
                    continue
                fi
                if [ "${pretend_list[$selected_domain_index]}" -eq 3 ]; then
                    yellow "不可选择重定向至重定向伪装网站，请重新选择！"
                    sleep 1
                    continue
                fi
                selected=1
                break
            done
            if [ $selected -eq 0 ]; then
                tyblue "info: 没有选择任何域名，重新配置伪装网站类型"
                sleep 3s
                continue
            fi
            pretend_redirect="${true_domain_list[$selected_domain_index]}"
            pretend_redirect_index=$selected_domain_index
        fi
        break
    done
}
readDomain()
{
    check_domain()
    {
        if [ -z "$1" ]; then
            return 1
        elif [ "$(wc -c <<< "$1")" -gt 47 ]; then
            red "域名过长！"
            return 1
        elif ! [[ "$1" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
            red "域名包含非法字符"
            return 1
        fi
        local domain
        for domain in "${domain_list[@]}"
        do
            if [ "$1" == "$domain" ]; then
                red "域名已 $domain 经存在！"
                return 1
            fi
        done
        for domain in "${true_domain_list[@]}"
        do
            if [ "$1" == "$domain" ]; then
                red "域名已 $domain 经存在！"
                return 1
            fi
        done
        return 0
    }
    local domain
    local domain_config=""
    echo -e "\\n\\n\\n"
    tyblue "--------------------请选择域名解析情况--------------------"
    tyblue " 1. 主域名 和 www.主域名 都解析到此服务器上 \\033[32m(推荐)"
    green  "    如：123.com 和 www.123.com 都解析到此服务器上"
    tyblue " 2. 仅某个特定域名解析到此服务器上"
    green  "    如：123.com 或 www.123.com 或 xxx.123.com 中的一个解析到此服务器上"
    echo
    while [ "$domain_config" != "1" ] && [ "$domain_config" != "2" ]
    do
        read -rp "您的选择是：" domain_config
    done
    while :
    do
        echo
        if [ $domain_config -eq 1 ]; then
            tyblue '---------请输入主域名(前面不带"www."、"http://"或"https://")---------'
            while :
            do
                read -rp "请输入域名：" domain
                if ! check_domain "$domain"; then
                    continue
                fi
                if [ "${domain%%.*}" == "www" ]; then
                    red "域名前面请不要带www！"
                    continue
                fi
                if ! check_domain "www.${domain}"; then
                    continue
                fi
                break
            done
        else
            tyblue '-------请输入解析到此服务器的域名(前面不带"http://"或"https://")-------'
            domain=""
            while ! check_domain "$domain"
            do
                read -rp "请输入域名：" domain
            done
        fi
        echo
        ! ask_if "您输入的域名是\"$domain\"，确认吗？(y/n)" && continue
        break
    done
    true_domain_list+=("$domain")
    [ $domain_config -eq 1 ] && domain_list+=("www.$domain") || domain_list+=("$domain")
    domain_config_list+=("$domain_config")
    local pretend
    local pretend_redirect
    local pretend_redirect_index
    readPretend $((${#domain_list[@]} - 1))
    pretend_list+=("$pretend")
    pretend_redirect_list+=("$pretend_redirect")
    pretend_redirect_index_list+=("$pretend_redirect_index")
}

#检查Nginx更新
check_nginx_update()
{
    local nginx_version_now
    local openssl_version_now
    nginx_version_now="nginx-$(${nginx_prefix}/sbin/nginx -V 2>&1 | grep "^nginx version:" | cut -d / -f 2)"
    openssl_version_now="openssl-openssl-$(${nginx_prefix}/sbin/nginx -V 2>&1 | grep "^built with OpenSSL" | awk '{print $4}')"
    if [ "$nginx_version_now" == "$nginx_version" ] && [ "$openssl_version_now" == "$openssl_version" ]; then
        return 1
    else
        return 0
    fi
}
#检查php更新
check_php_update()
{
    local php_version_now
    php_version_now="php-$(${php_prefix}/bin/php -v | head -n 1 | awk '{print $2}')"
    [ "$php_version_now" == "$php_version" ] && return 1
    return 0
}
install_nginx_compile_toolchains()
{
    green "正在安装Nginx编译工具链。。。"
    if [ "$distro_like" == "rhel" ]; then
        install_dependencies ca-certificates curl gcc gcc-c++ make perl-IPC-Cmd perl-Getopt-Long perl-Data-Dumper
        if ! perl -e "use FindBin" > /dev/null 2>&1; then
            install_dependencies perl-FindBin
        fi
    else
        install_dependencies ca-certificates curl gcc g++ make perl-base perl
    fi
}
install_php_compile_toolchains()
{
    green "正在安装php编译工具链。。。"
    if [ "$distro_like" == "rhel" ]; then
        install_dependencies ca-certificates curl xz gcc gcc-c++ make pkgconf-pkg-config autoconf git
    else
        install_dependencies ca-certificates curl xz-utils gcc g++ make pkg-config autoconf git
    fi
}
install_nginx_dependencies()
{
    green "正在安装Nginx依赖。。。"
    if [ "$distro_like" == "rhel" ]; then
        install_dependencies pcre2-devel zlib-devel libxml2-devel libxslt-devel gd-devel geoip-devel perl-ExtUtils-Embed gperftools-devel perl-devel
    else
        install_dependencies libpcre2-dev zlib1g-dev libxml2-dev libxslt1-dev libgd-dev libgeoip-dev libgoogle-perftools-dev libperl-dev
    fi
}
install_php_dependencies()
{
    green "正在安装php依赖。。。"
    if [ "$distro_like" == "rhel" ]; then
        install_dependencies libxml2-devel sqlite-devel systemd-devel libacl-devel openssl-devel krb5-devel pcre2-devel zlib-devel bzip2-devel libcurl-devel gdbm-devel libdb-devel tokyocabinet-devel lmdb-devel enchant-devel libffi-devel libpng-devel gd-devel libwebp-devel libjpeg-turbo-devel libXpm-devel freetype-devel gmp-devel uw-imap-devel libicu-devel openldap-devel oniguruma-devel unixODBC-devel freetds-devel libpq-devel aspell-devel libedit-devel net-snmp-devel libsodium-devel libargon2-devel libtidy-devel libxslt-devel libzip-devel ImageMagick-devel tzdata
    else
        if try_install_dependencies libxml2-dev libsqlite3-dev libsystemd-dev libacl1-dev libapparmor-dev libssl-dev libkrb5-dev libpcre2-dev zlib1g-dev libbz2-dev libcurl4-openssl-dev libqdbm-dev libdb-dev libtokyocabinet-dev liblmdb-dev libenchant-2-dev libffi-dev libpng-dev libgd-dev libwebp-dev libjpeg-dev libxpm-dev libfreetype6-dev libgmp-dev libc-client2007e-dev libicu-dev libldap2-dev libsasl2-dev libonig-dev unixodbc-dev freetds-dev libpq-dev libpspell-dev libedit-dev libmm-dev libsnmp-dev libsodium-dev libargon2-dev libtidy-dev libxslt1-dev libzip-dev libmagickwand-dev tzdata; then
            return 0
        fi
        install_dependencies libxml2-dev libsqlite3-dev libsystemd-dev libacl1-dev libapparmor-dev libssl-dev libkrb5-dev libpcre2-dev zlib1g-dev libbz2-dev libcurl4-openssl-dev libqdbm-dev libdb-dev libtokyocabinet-dev liblmdb-dev libenchant-dev libffi-dev libpng-dev libgd-dev libwebp-dev libjpeg-dev libxpm-dev libfreetype6-dev libgmp-dev libc-client2007e-dev libicu-dev libldap2-dev libsasl2-dev libonig-dev unixodbc-dev freetds-dev libpq-dev libpspell-dev libedit-dev libmm-dev libsnmp-dev libsodium-dev libargon2-dev libtidy-dev libxslt1-dev libzip-dev libmagickwand-dev tzdata
    fi
}
install_acme_dependencies()
{
    green "正在安装acme.sh依赖。。。"
    if [ "$distro_like" == "rhel" ]; then
        install_dependencies curl openssl crontabs
    else
        install_dependencies curl openssl cron
    fi
}
install_web_dependencies()
{
    green "正在安装伪装网站依赖。。。"
    if [ -z "$1" ]; then
        for i in "${pretend_list[@]}"
        do
            if [ "$i" == "1" ]; then
                install_dependencies ca-certificates curl
                break
            fi
        done
        for i in "${pretend_list[@]}"
        do
            if [ "$i" == "2" ]; then
                install_dependencies ca-certificates curl bzip2
                break
            fi
        done
    else
        if [ "$1" == "1" ]; then
            install_dependencies ca-certificates curl
        elif [ "$1" == "2" ]; then
            install_dependencies ca-certificates curl bzip2
        fi
    fi
}
gen_cflags()
{
    cflags=('-g0' '-Ofast' -march=native -mtune=native)
    if gcc -v --help 2>&1 | grep -qw "\\-fstack\\-reuse"; then
        cflags+=('-fstack-reuse=all')
    fi
    if gcc -v --help 2>&1 | grep -qw "\\-fexceptions"; then
        cflags+=('-fno-exceptions')
    elif gcc -v --help 2>&1 | grep -qw "\\-fhandle\\-exceptions"; then
        cflags+=('-fno-handle-exceptions')
    fi
    if gcc -v --help 2>&1 | grep -qw "\\-funwind\\-tables"; then
        cflags+=('-fno-unwind-tables')
    fi
    if gcc -v --help 2>&1 | grep -qw "\\-fasynchronous\\-unwind\\-tables"; then
        cflags+=('-fno-asynchronous-unwind-tables')
    fi
    if gcc -v --help 2>&1 | grep -qw "\\-fstack\\-check"; then
        cflags+=('-fno-stack-check')
    fi
    if gcc -v --help 2>&1 | grep -qw "\\-fstack\\-clash\\-protection"; then
        cflags+=('-fno-stack-clash-protection')
    fi
    if gcc -v --help 2>&1 | grep -qw "\\-fstack\\-protector"; then
        cflags+=('-fno-stack-protector')
    fi
    if gcc -v --help 2>&1 | grep -qw "\\-fcf\\-protection="; then
        cflags+=('-fcf-protection=none')
    fi
    if gcc -v --help 2>&1 | grep -qw "\\-fsplit\\-stack"; then
        cflags+=('-fno-split-stack')
    fi
    if gcc -v --help 2>&1 | grep -qw "\\-fsanitize"; then
        : > temp.c
        if gcc -E -fno-sanitize=all temp.c >/dev/null 2>&1; then
            cflags+=('-fno-sanitize=all')
        fi
        rm temp.c
    fi
    if gcc -v --help 2>&1 | grep -qw "\\-finstrument\\-functions"; then
        cflags+=('-fno-instrument-functions')
    fi
}
gen_cxxflags()
{
    cxxflags=('-g0' '-Ofast' -march=native -mtune=native)
    if g++ -v --help 2>&1 | grep -qw "\\-fstack\\-reuse"; then
        cxxflags+=('-fstack-reuse=all')
    fi
    if g++ -v --help 2>&1 | grep -qw "\\-fstack\\-check"; then
        cxxflags+=('-fno-stack-check')
    fi
    if g++ -v --help 2>&1 | grep -qw "\\-fstack\\-clash\\-protection"; then
        cxxflags+=('-fno-stack-clash-protection')
    fi
    if g++ -v --help 2>&1 | grep -qw "\\-fstack\\-protector"; then
        cxxflags+=('-fno-stack-protector')
    fi
    if g++ -v --help 2>&1 | grep -qw "\\-fcf\\-protection="; then
        cxxflags+=('-fcf-protection=none')
    fi
    if g++ -v --help 2>&1 | grep -qw "\\-fsplit\\-stack"; then
        cxxflags+=('-fno-split-stack')
    fi
    if g++ -v --help 2>&1 | grep -qw "\\-fsanitize"; then
        : > temp.cpp
        if g++ -E -fno-sanitize=all temp.cpp >/dev/null 2>&1; then
            cxxflags+=('-fno-sanitize=all')
        fi
        rm temp.cpp
    fi
    if g++ -v --help 2>&1 | grep -qw "\\-finstrument\\-functions"; then
        cxxflags+=('-fno-instrument-functions')
    fi
    if g++ -v --help 2>&1 | grep -qw "\\-fvtable\\-verify"; then
        cxxflags+=('-fvtable-verify=none')
    fi
}
swap_on()
{
    if [ $using_swap_now -ne 0 ]; then
        red    "swap开启冲突！"
        report_bug
    fi
    if ! rm -f "${temp_dir}/swap"; then
        swapoff "${temp_dir}/swap"
        if ! rm -f "${temp_dir}/swap"; then
            red "路径${temp_dir}/swap被占用"
            report_bug
        fi
    fi
    local need_swap_size
    local current_free_mem_size
    current_free_mem_size=$(($(free -b | sed -n 2p | awk '{print $2}') - $(free -b | sed -n 2p | awk '{print $3}') + $(free -b | sed -n 3p | awk '{print $2}') - $(free -b | sed -n 3p | awk '{print $3}')))
    need_swap_size=$(($1 - current_free_mem_size / 1024 / 1024))
    if [ $need_swap_size -gt 0 ]; then
        tyblue "可用内存不足$1M，自动申请swap。。"
        if dd if=/dev/zero of="${temp_dir}/swap" bs=1M count=$need_swap_size && chmod 0600 "${temp_dir}/swap" && mkswap "${temp_dir}/swap" && swapon "${temp_dir}/swap"; then
            using_swap_now=1
        else
            rm -f  "${temp_dir}/swap"
            red    "开启swap失败！"
            yellow "可能是机器内存和硬盘空间都不足"
            report_bug
        fi
    fi
}
swap_off()
{
    if [ $using_swap_now -eq 1 ]; then
        tyblue "正在恢复swap。。。"
        if swapoff "${temp_dir}/swap" && rm -f "${temp_dir}/swap"; then
            using_swap_now=0
        else
            red    "关闭swap失败！"
            report_bug
        fi
    fi
}

#编译&&安装php
compile_php()
{
    green "正在编译php。。。。"
    local cflags
    local cxxflags
    gen_cflags
    gen_cxxflags
    if ! curl -Lo "${php_version}.tar.xz" "https://www.php.net/distributions/${php_version}.tar.xz"; then
        red    "获取php失败"
        report_bug
    fi
    tar -xJf "${php_version}.tar.xz"
    rm -f "${php_version}.tar.xz"
    cd "${php_version}"
    sed -i 's#db$THIS_VERSION/db_185.h include/db$THIS_VERSION/db_185.h include/db/db_185.h#& include/db_185.h#' configure
    if [ "$distro_like" == "debian" ]; then
        sed -i 's#if test -f $THIS_PREFIX/$PHP_LIBDIR/lib$LIB.a || test -f $THIS_PREFIX/$PHP_LIBDIR/lib$LIB.$SHLIB_SUFFIX_NAME#& || true#' configure
        sed -i 's#if test ! -r "$PDO_FREETDS_INSTALLATION_DIR/$PHP_LIBDIR/libsybdb.a" && test ! -r "$PDO_FREETDS_INSTALLATION_DIR/$PHP_LIBDIR/libsybdb.so"#& \&\& false#' configure
        ./configure --prefix="${php_prefix}" --enable-embed=shared --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --with-fpm-systemd --with-fpm-acl --with-fpm-apparmor --disable-phpdbg --with-layout=GNU --with-openssl --with-kerberos --with-external-pcre --with-zlib --enable-bcmath --with-bz2 --enable-calendar --with-curl --enable-dba --with-qdbm --with-db4 --with-db1 --with-tcadb --with-lmdb --with-enchant --enable-exif --with-ffi --enable-ftp --enable-gd --with-external-gd --with-avif --with-webp --with-jpeg --with-xpm --with-freetype --enable-gd-jis-conv --with-gettext --with-gmp --with-mhash --with-imap --with-imap-ssl --enable-intl --with-ldap --with-ldap-sasl --enable-mbstring --with-mysqli --with-mysql-sock --with-unixODBC --enable-pcntl --with-pdo-dblib --with-pdo-mysql --with-zlib-dir --with-pdo-odbc=unixODBC,/usr --with-pdo-pgsql --with-pgsql --with-pspell --with-libedit --with-mm --enable-shmop --with-snmp --enable-soap --enable-sockets --with-sodium --with-external-libcrypt --with-password-argon2 --enable-sysvmsg --enable-sysvsem --enable-sysvshm --with-tidy --with-xsl --with-zip --enable-mysqlnd --with-pear CFLAGS="${cflags[*]}" CXXFLAGS="${cxxflags[*]}"
    else
        ./configure --prefix="${php_prefix}" --with-libdir=lib64 --enable-embed=shared --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --with-fpm-systemd --with-fpm-acl --disable-phpdbg --with-layout=GNU --with-openssl --with-kerberos --with-external-pcre --with-zlib --enable-bcmath --with-bz2 --enable-calendar --with-curl --enable-dba --with-gdbm --with-db4 --with-db1 --with-tcadb --with-lmdb --with-enchant --enable-exif --with-ffi --enable-ftp --enable-gd --with-external-gd --with-avif --with-webp --with-jpeg --with-xpm --with-freetype --enable-gd-jis-conv --with-gettext --with-gmp --with-mhash --with-imap --with-imap-ssl --enable-intl --with-ldap --with-ldap-sasl --enable-mbstring --with-mysqli --with-mysql-sock --with-unixODBC --enable-pcntl --with-pdo-dblib --with-pdo-mysql --with-zlib-dir --with-pdo-odbc=unixODBC,/usr --with-pdo-pgsql --with-pgsql --with-pspell --with-libedit --enable-shmop --with-snmp --enable-soap --enable-sockets --with-sodium --with-external-libcrypt --with-password-argon2 --enable-sysvmsg --enable-sysvsem --enable-sysvshm --with-tidy --with-xsl --with-zip --enable-mysqlnd --with-pear CFLAGS="${cflags[*]}" CXXFLAGS="${cxxflags[*]}"
    fi
    swap_on 2048
    if ! make -j$((nproc * 2)); then
        swap_off
        red    "php编译失败！"
        report_bug
    fi
    swap_off
    cd ..
}
instal_php_imagick()
{
    local cflags
    gen_cflags
    if ! git clone https://github.com/Imagick/imagick; then
        yellow "获取php-imagick源码失败"
        report_bug
    fi
    cd imagick
    "${php_prefix}/bin/phpize"
    ./configure --with-php-config="${php_prefix}/bin/php-config" CFLAGS="${cflags[*]}"
    swap_on 380
    if ! make -j$nproc; then
        swap_off
        yellow "php-imagick编译失败"
        report_bug
    else
        swap_off
    fi
    local dest
    dest="$("${php_prefix}/bin/php" -i | grep "^extension_dir" | awk '{print $3}')"
    if ! [[ "$dest" =~ ^"${php_prefix}" ]]; then
        red "获取PHP extension_dir 异常！"
        report_bug
    fi
    if ! mv modules/imagick.so "$dest"; then
        red "PHP安装失败！"
        report_bug
    fi
    cd ..
    rm -rf imagick
}
install_php_part1()
{
    green "正在安装php。。。。"
    cd "${php_version}"
    make install
    mv sapi/fpm/php-fpm.service "${php_prefix}/php-fpm.service.default.temp"
    mv php.ini-production "${php_prefix}"
    mv php.ini-development "${php_prefix}"
    cd ..
    rm -rf "${php_version}"
    instal_php_imagick
    mv "${php_prefix}/php-fpm.service.default.temp" "${php_prefix}/php-fpm.service.default"
}
install_php_part2()
{
    useradd -r -s /bin/bash www-data
    cp "${php_prefix}/etc/php-fpm.conf.default" "${php_prefix}/etc/php-fpm.conf"
    cp "${php_prefix}/etc/php-fpm.d/www.conf.default" "${php_prefix}/etc/php-fpm.d/www.conf"
    sed -i 's/^[ \t]*listen[ \t]*=/;&/g' "${php_prefix}/etc/php-fpm.d/www.conf"
    sed -i 's/^[ \t]*env\[PATH\][ \t]*=/;&/g' "${php_prefix}/etc/php-fpm.d/www.conf"
cat >> "${php_prefix}/etc/php-fpm.d/www.conf" << EOF

listen = /run/php-fpm/php-fpm.sock
pm = dynamic
pm.max_children = $((16*nproc))
pm.start_servers = $nproc
pm.min_spare_servers = $nproc
pm.max_spare_servers = $((16*nproc))
env[PATH] = $PATH
EOF
    rm -rf "${php_prefix}/etc/php.ini"
    cp "${php_prefix}/php.ini-production" "${php_prefix}/etc/php.ini"
    local timezone
    timezone="$(cat /etc/timezone)"
    if [[ "$timezone" != "$(ls -l /etc/localtime | awk -F zoneinfo/ '{print $NF}')" ]]; then
        red "时区信息不自洽：$timezone  $(ls -l /etc/localtime | awk -F zoneinfo/ '{print $NF}')"
        report_bug
    fi
cat >> "${php_prefix}/etc/php.ini" << EOF

[PHP]
extension=imagick.so
zend_extension=opcache.so
opcache.enable=1
date.timezone=$timezone

;如果使用mysql，并且使用unix domain socket方式连接，请正确设置以下内容
;pdo_mysql.default_socket=/var/run/mysqld/mysqld.sock
;mysqli.default_socket=/var/run/mysqld/mysqld.sock

memory_limit=-1
post_max_size=0
upload_max_filesize=9223372036854775807
max_file_uploads=50000
max_execution_time=0
max_input_time=0
output_buffering=4096
session.auto_start=0
EOF
    install -m 644 "${php_prefix}/php-fpm.service.default" "$php_service"
cat >> "$php_service" <<EOF

[Service]
ProtectSystem=false
ExecStartPre="$(type -P rm)" -rf /run/php-fpm
ExecStartPre="$(type -P mkdir)" /run/php-fpm
ExecStartPre="$(type -P chmod)" 711 /run/php-fpm
ExecStartPre="$(type -P chown)" www-data:www-data /run/php-fpm
ExecStopPost="$(type -P rm)" -rf /run/php-fpm
EOF
    systemctl daemon-reload
    php_is_installed=1
}

#编译&&安装nignx
compile_nginx()
{
    green "正在编译Nginx。。。。"
    local cflags
    gen_cflags
cat > "$temp_dir/gcc-defaultpie" << EOF
#!/bin/bash
gcc -fpie -pie "\$@"
EOF
    chmod +x "$temp_dir/gcc-defaultpie"
    if ! curl -Lo "${nginx_version}.tar.gz" "https://nginx.org/download/${nginx_version}.tar.gz"; then
        red    "获取nginx失败"
        report_bug
    fi
    tar -zxf "${nginx_version}.tar.gz"
    rm -f "${nginx_version}.tar.gz"
    if ! curl -Lo "${openssl_version}.tar.gz" "https://github.com/openssl/openssl/archive/${openssl_version#*-}.tar.gz"; then
        red    "获取openssl失败"
        report_bug
    fi
    tar -zxf "${openssl_version}.tar.gz"
    rm -f "${openssl_version}.tar.gz"
    cd "${nginx_version}"
    sed -i "s/OPTIMIZE[ \\t]*=>[ \\t]*'-O'/OPTIMIZE          => '-Ofast'/g" src/http/modules/perl/Makefile.PL
    sed -i 's/NGX_PERL_CFLAGS="$CFLAGS `$NGX_PERL -MExtUtils::Embed -e ccopts`"/NGX_PERL_CFLAGS="`$NGX_PERL -MExtUtils::Embed -e ccopts` $CFLAGS"/g' auto/lib/perl/conf
    sed -i 's/NGX_PM_CFLAGS=`$NGX_PERL -MExtUtils::Embed -e ccopts`/NGX_PM_CFLAGS="`$NGX_PERL -MExtUtils::Embed -e ccopts` $CFLAGS"/g' auto/lib/perl/conf
    ./configure --prefix="${nginx_prefix}" --user=root --group=root --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module --with-mail --with-mail_ssl_module --with-stream --with-stream_ssl_module --with-stream_realip_module --with-stream_geoip_module --with-stream_ssl_preread_module --with-google_perftools_module --with-compat --with-cc-opt="${cflags[*]}" --with-openssl="../$openssl_version" --with-openssl-opt="${cflags[*]}" --with-cc="$temp_dir/gcc-defaultpie"
    #--with-select_module --with-poll_module --with-cpp_test_module --with-pcre --with-pcre-jit --with-libatomic
    #./configure --prefix=/usr/local/nginx --with-openssl=../$openssl_version --with-mail=dynamic --with-mail_ssl_module --with-stream=dynamic --with-stream_ssl_module --with-stream_realip_module --with-stream_geoip_module=dynamic --with-stream_ssl_preread_module --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module=dynamic --with-pcre --with-libatomic --with-compat --with-cpp_test_module --with-google_perftools_module --with-file-aio --with-threads --with-poll_module --with-select_module --with-cc-opt="-Wno-error ${cflags[*]}"
    swap_on 480
    if ! make -j$((nproc * 3)); then
        swap_off
        red    "Nginx编译失败！"
        report_bug
    fi
    swap_off
    cd ..
}
config_service_nginx()
{
    rm -rf "$nginx_service"
cat > "$nginx_service" << EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
User=root
ExecStartPre="$(type -P rm)" -rf /run/nginx
ExecStartPre="$(type -P mkdir)" /run/nginx
ExecStartPre="$(type -P chmod)" 711 /run/nginx
ExecStartPre="$(type -P mkdir)" /run/nginx/tcmalloc
ExecStartPre="$(type -P chmod)" 0777 /run/nginx/tcmalloc
ExecStart=${nginx_prefix}/sbin/nginx
ExecStop=${nginx_prefix}/sbin/nginx -s stop
ExecStopPost="$(type -P rm)" -rf /run/nginx
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 "$nginx_service"
    systemctl daemon-reload
}
install_nginx_part1()
{
    green "正在安装Nginx。。。"
    cd "${nginx_version}"
    make install
    cd ..
    rm -rf "${nginx_version}"
    rm -rf "$openssl_version"
}
install_nginx_part2()
{
    mkdir "${nginx_prefix}/conf.d"
    touch "$nginx_config"
    mkdir "${nginx_prefix}/certs"
    mkdir "${nginx_prefix}/html/issue_certs"
cat > "${nginx_prefix}/conf/issue_certs.conf" << EOF
events {
    worker_connections  1024;
}
http {
    server {
        listen [::]:80 ipv6only=off;
        root ${nginx_prefix}/html/issue_certs;
    }
}
EOF
cat > "${nginx_prefix}/conf.d/nextcloud.conf" <<EOF
    client_max_body_size 0;
    #client_body_timeout 300s;
    fastcgi_buffers 64 4K;
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;
    add_header Referrer-Policy                      "no-referrer"   always;
    add_header X-Content-Type-Options               "nosniff"       always;
    add_header X-Download-Options                   "noopen"        always;
    add_header X-Frame-Options                      "SAMEORIGIN"    always;
    add_header X-Permitted-Cross-Domain-Policies    "none"          always;
    add_header X-Robots-Tag                         "none"          always;
    add_header X-XSS-Protection                     "1; mode=block" always;
    fastcgi_hide_header X-Powered-By;
    index index.php index.html /index.php\$request_uri;
    location = / {
        if ( \$http_user_agent ~ ^DavClnt ) {
            return 302 https://\$host/remote.php/webdav/\$is_args\$args;
        }
    }
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
    location ^~ /.well-known {
        location = /.well-known/carddav { return 301 https://\$host/remote.php/dav/; }
        location = /.well-known/caldav  { return 301 https://\$host/remote.php/dav/; }
        location /.well-known/acme-challenge    { try_files \$uri \$uri/ =404; }
        location /.well-known/pki-validation    { try_files \$uri \$uri/ =404; }
        return 301 https://\$host/index.php\$request_uri;
    }
    location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)  { return 404; }
    location ~ ^/(?:\\.|autotest|occ|issue|indie|db_|console)                { return 404; }
    location ~ \\.php(?:$|/) {
        rewrite ^/(?!index|remote|public|cron|core\\/ajax\\/update|status|ocs\\/v[12]|updater\\/.+|oc[ms]-provider\\/.+|.+\\/richdocumentscode\\/proxy) /index.php\$request_uri;
        fastcgi_split_path_info ^(.+?\\.php)(/.*)$;
        set \$path_info \$fastcgi_path_info;
        try_files \$fastcgi_script_name =404;
        include fastcgi.conf;
        fastcgi_param PATH_INFO \$path_info;
        fastcgi_param REMOTE_ADDR 127.0.0.1;
        fastcgi_param SERVER_PORT 443;
        fastcgi_param HTTPS on;
        fastcgi_param modHeadersAvailable true;
        fastcgi_param front_controller_active true;
        fastcgi_pass unix:/run/php-fpm/php-fpm.sock;
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
        fastcgi_read_timeout 24h;
        fastcgi_max_temp_file_size 0;
    }
    location ~ \\.(?:css|js|svg|gif|png|jpg|ico)$ {
        try_files \$uri /index.php\$request_uri;
        expires 6M;
        access_log off;
    }
    location ~ \\.woff2?$ {
        try_files \$uri /index.php\$request_uri;
        expires 7d;
        access_log off;
    }
    location /remote {
        return 301 https://\$host/remote.php\$request_uri;
    }
    location / {
        try_files \$uri \$uri/ /index.php\$request_uri;
    }
EOF
    config_service_nginx
    systemctl enable nginx
    nginx_is_installed=1
    [ $xray_is_installed -eq 1 ] && is_installed=1 || is_installed=0
}


#安装/更新Xray
install_update_xray()
{
    green "正在安装/更新Xray。。。。"
    local script_src
    if { ! script_src="$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" && ! script_src="$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)"; } || [ -z "$script_src" ]; then
        red "获取Xray安装脚本失败！"
        report_bug
        return 1
    fi
    if ! bash <(echo "${script_src}") install -u root --without-geodata --without-logfiles --beta; then
        red    "安装/更新Xray失败"
        report_bug
        return 1
    fi
    if ! grep -q "# This file has been edited by Xray-REALITY-Web setup script" /etc/systemd/system/xray.service; then
cat >> /etc/systemd/system/xray.service <<EOF

# This file has been edited by Xray-REALITY-Web setup script
[Service]
ExecStartPre="$(type -P rm)" -rf /run/xray
ExecStartPre="$(type -P mkdir)" /run/xray
ExecStartPre="$(type -P chmod)" 711 /run/xray
ExecStopPost="$(type -P rm)" -rf /run/xray
EOF
        systemctl daemon-reload
        systemctl -q is-active xray && systemctl restart xray
    fi
    xray_is_installed=1
    [ $nginx_is_installed -eq 1 ] && is_installed=1 || is_installed=0
}

# 此函数将启动/重启Nginx，但启动时配置是错的，调用后需要自行重启Nginx
#获取证书 参数: 域名位置
get_cert()
{
    if [ "${domain_config_list[$1]}" -eq 1 ]; then
        green "正在获取 \"${domain_list[$1]}\"、\"${true_domain_list[$1]}\" 的域名证书"
    else
        green "正在获取 \"${domain_list[$1]}\" 的域名证书"
    fi
    mv "${nginx_prefix}/conf/nginx.conf" "${nginx_prefix}/conf/nginx.conf.bak2"
    cp "${nginx_prefix}/conf/nginx.conf.default" "${nginx_prefix}/conf/nginx.conf"
    local temp=()
    [ "${domain_config_list[$1]}" -eq 1 ] && temp=("-d" "${domain_list[$1]}")
    if ! "$HOME/.acme.sh/acme.sh" --issue -d "${true_domain_list[$1]}" "${temp[@]}" -w "${nginx_prefix}/html/issue_certs" -k ec-256 -ak ec-256 --pre-hook "mv ${nginx_prefix}/conf/nginx.conf ${nginx_prefix}/conf/nginx.conf.bak && cp ${nginx_prefix}/conf/issue_certs.conf ${nginx_prefix}/conf/nginx.conf && systemctl restart nginx && sleep 2s" --post-hook "mv ${nginx_prefix}/conf/nginx.conf.bak ${nginx_prefix}/conf/nginx.conf && systemctl restart nginx && sleep 2s" --ocsp && ! "$HOME/.acme.sh/acme.sh" --issue -d "${true_domain_list[$1]}" "${temp[@]}" -w "${nginx_prefix}/html/issue_certs" -k ec-256 -ak ec-256 --server letsencrypt --pre-hook "mv ${nginx_prefix}/conf/nginx.conf ${nginx_prefix}/conf/nginx.conf.bak && cp ${nginx_prefix}/conf/issue_certs.conf ${nginx_prefix}/conf/nginx.conf && systemctl restart nginx && sleep 2s" --post-hook "mv ${nginx_prefix}/conf/nginx.conf.bak ${nginx_prefix}/conf/nginx.conf && systemctl restart nginx && sleep 2s" --ocsp; then
        "$HOME/.acme.sh/acme.sh" --issue -d "${true_domain_list[$1]}" "${temp[@]}" -w "${nginx_prefix}/html/issue_certs" -k ec-256 -ak ec-256 --pre-hook "mv ${nginx_prefix}/conf/nginx.conf ${nginx_prefix}/conf/nginx.conf.bak && cp ${nginx_prefix}/conf/issue_certs.conf ${nginx_prefix}/conf/nginx.conf && systemctl restart nginx && sleep 2s" --post-hook "mv ${nginx_prefix}/conf/nginx.conf.bak ${nginx_prefix}/conf/nginx.conf && systemctl restart nginx && sleep 2s" --ocsp --debug || "$HOME/.acme.sh/acme.sh" --issue -d "${true_domain_list[$1]}" "${temp[@]}" -w "${nginx_prefix}/html/issue_certs" -k ec-256 -ak ec-256 --server letsencrypt --pre-hook "mv ${nginx_prefix}/conf/nginx.conf ${nginx_prefix}/conf/nginx.conf.bak && cp ${nginx_prefix}/conf/issue_certs.conf ${nginx_prefix}/conf/nginx.conf && systemctl restart nginx && sleep 2s" --post-hook "mv ${nginx_prefix}/conf/nginx.conf.bak ${nginx_prefix}/conf/nginx.conf && systemctl restart nginx && sleep 2s" --ocsp --debug
    fi
    if ! "$HOME/.acme.sh/acme.sh" --installcert -d "${true_domain_list[$1]}" --key-file "${nginx_prefix}/certs/${true_domain_list[$1]}.key" --fullchain-file "${nginx_prefix}/certs/${true_domain_list[$1]}.cer" --reloadcmd "systemctl restart nginx && sleep 2s" --ecc; then
        "$HOME/.acme.sh/acme.sh" --remove --domain "${true_domain_list[$1]}" --ecc
        rm -rf "$HOME/.acme.sh/${true_domain_list[$1]}_ecc"
        rm -rf "${nginx_prefix}/certs/${true_domain_list[$1]}.key" "${nginx_prefix}/certs/${true_domain_list[$1]}.cer"
        mv "${nginx_prefix}/conf/nginx.conf.bak2" "${nginx_prefix}/conf/nginx.conf"
        return 1
    fi
    mv "${nginx_prefix}/conf/nginx.conf.bak2" "${nginx_prefix}/conf/nginx.conf"
    return 0
}
get_all_certs()
{
    local i
    for ((i=0;i<${#domain_list[@]};i++))
    do
        if ! get_cert "$i"; then
            red    "域名\"${true_domain_list[$i]}\"证书申请失败！"
            yellow "请检查："
            yellow "    1.域名是否解析正确"
            yellow "    2.vps防火墙80端口是否开放"
            yellow "并在安装/重置域名完成后，使用脚本主菜单\"重置域名\"选项修复"
            report_bug
        fi
    done
}

#配置nginx
config_nginx_init()
{
cat > "${nginx_prefix}/conf/nginx.conf" <<EOF

user  root root;
worker_processes  auto;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;
google_perftools_profiles /run/nginx/tcmalloc/tcmalloc;

events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
    #                  '\$status \$body_bytes_sent "\$http_referer" '
    #                  '"\$http_user_agent" "\$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    include       $nginx_config;
    #server {
        #listen       80;
        #server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        #location / {
        #    root   html;
        #    index  index.html index.htm;
        #}

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        #error_page   500 502 503 504  /50x.html;
        #location = /50x.html {
        #    root   html;
        #}

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \\.php\$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \\.php\$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts\$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\\.ht {
        #    deny  all;
        #}
    #}


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;

    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;

    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

}
EOF
}
config_nginx()
{
    config_nginx_init
    local i
cat > "$nginx_config"<<EOF
server {
    listen 80 reuseport default_server;
    listen [::]:80 reuseport default_server;
    return 301 https://${domain_list[0]};
}
server {
    listen 80;
    listen [::]:80;
    server_name ${domain_list[@]};
    return 301 https://\$host\$request_uri;
}
EOF
    local temp_domain_list2=()
    for i in "${!domain_config_list[@]}"
    do
        [ ${domain_config_list[$i]} -eq 1 ] && temp_domain_list2+=("${true_domain_list[$i]}")
    done
    if [ ${#temp_domain_list2[@]} -ne 0 ]; then
cat >> "$nginx_config" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${temp_domain_list2[@]};
    return 301 https://www.\$host\$request_uri;
}
EOF
    fi
cat >> "$nginx_config"<<EOF
server {
    listen unix:/run/nginx/ssl.sock ssl default_server;
    http2 on;
    ssl_certificate         ${nginx_prefix}/certs/${true_domain_list[0]}.cer;
    ssl_certificate_key     ${nginx_prefix}/certs/${true_domain_list[0]}.key;
    ssl_protocols           TLSv1.3 TLSv1.2;
    ssl_ciphers             ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305;
    return 301 https://${domain_list[0]};
}
EOF
    local domain
    for domain in "${temp_domain_list2[@]}"
    do
cat >> "$nginx_config"<<EOF
server {
    listen unix:/run/nginx/ssl.sock ssl;
    http2 on;
    ssl_certificate         ${nginx_prefix}/certs/${domain}.cer;
    ssl_certificate_key     ${nginx_prefix}/certs/${domain}.key;
    server_name ${domain};
    ssl_protocols           TLSv1.3 TLSv1.2;
    ssl_ciphers             ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305;
    ssl_stapling            on;
    ssl_stapling_verify     on;
    ssl_trusted_certificate ${nginx_prefix}/certs/${domain}.cer;
    add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload" always;
    return 301 https://www.\$host\$request_uri;
}
EOF
    done
    local redirect
    for ((i=0;i<${#domain_list[@]};i++))
    do
cat >> "$nginx_config"<<EOF
server {
    listen unix:/run/nginx/ssl.sock ssl;
    http2 on;
    ssl_certificate         ${nginx_prefix}/certs/${true_domain_list[$i]}.cer;
    ssl_certificate_key     ${nginx_prefix}/certs/${true_domain_list[$i]}.key;
    server_name ${domain_list[$i]};
    ssl_protocols           TLSv1.3 TLSv1.2;
    ssl_ciphers             ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305;
    ssl_stapling            on;
    ssl_stapling_verify     on;
    ssl_trusted_certificate ${nginx_prefix}/certs/${true_domain_list[$i]}.cer;
    add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload" always;
EOF
        if [ $protocol_2 -ne 0 ]; then
cat >> "$nginx_config"<<EOF
    #client_header_timeout 24h;
    #ignore_invalid_headers off;
    location = /$serviceName/TunMulti {
        client_max_body_size 0;
        client_body_timeout 24h;
        #keepalive_requests 1000;
        #keepalive_time 24h;
        keepalive_timeout 24h;
        send_timeout 24h;
        #grpc_buffer_size 0;
        grpc_read_timeout 24h;
        grpc_send_timeout 24h;
        #grpc_socket_keepalive off;
        lingering_close always;
        lingering_time 24h;
        lingering_timeout 24h;
        grpc_pass grpc://unix:/run/xray/grpc.sock;
    }
EOF
        fi
        if [ $protocol_3 -ne 0 ]; then
cat >> "$nginx_config"<<EOF
    location = $path {
        proxy_redirect off;
        proxy_pass http://unix:/run/xray/ws.sock;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
EOF
        fi
        if [ "${pretend_list[$i]}" -eq 1 ]; then
cat >> "$nginx_config"<<EOF
    location / {
        proxy_set_header X-Forwarded-For 127.0.0.1;
        proxy_set_header Host \$http_host;
        proxy_redirect off;
        proxy_pass http://unix:${nginx_prefix}/html/${true_domain_list[$i]}/cloudreve.sock;
        client_max_body_size 0;
    }
EOF
        elif [ "${pretend_list[$i]}" -eq 2 ]; then
cat >> "$nginx_config" << EOF
    root ${nginx_prefix}/html/${true_domain_list[$i]};
    include ${nginx_prefix}/conf.d/nextcloud.conf;
EOF
        elif [ "${pretend_list[$i]}" -eq 3 ]; then
            redirect="${pretend_redirect_index_list[$i]}"
            if [ "${pretend_list[$redirect]}" -eq 1 ]; then
cat >> "$nginx_config"<<EOF
    location / {
        proxy_set_header X-Forwarded-For 127.0.0.1;
        proxy_set_header Host \$http_host;
        proxy_redirect off;
        proxy_pass http://unix:${nginx_prefix}/html/${pretend_redirect_list[$i]}/cloudreve.sock;
        client_max_body_size 0;
    }
EOF
            elif [ "${pretend_list[$redirect]}" -eq 2 ]; then
cat >> "$nginx_config" << EOF
    root ${nginx_prefix}/html/${pretend_redirect_list[$i]};
    include ${nginx_prefix}/conf.d/nextcloud.conf;
EOF
            elif [ "${pretend_list[$redirect]}" -eq 3 ]; then
                red "异常行为：redirect to redirect"
                report_bug_exit
            fi
        fi
        echo "}" >> $nginx_config
    done
cat >> "$nginx_config" << EOF
#-----------------不要修改以下内容----------------
#domain_list=${domain_list[@]}
#true_domain_list=${true_domain_list[@]}
#domain_config_list=${domain_config_list[@]}
#pretend_list=${pretend_list[@]}
#pretend_redirect_list=${pretend_redirect_list[@]}
EOF
}

#配置xray
config_xray()
{
    local i
cat > "$xray_config" <<EOF
{
    "log": {
        "loglevel": "none"
    },
    "inbounds": [
        {
            "port": 443,
            "protocol": "vless",
            "settings": {
EOF
    if [ "$protocol_1" -ne 0 ]; then
cat >> "$xray_config" <<EOF
                "clients": [
                    {
                        "id": "${xid_1}",
                        "flow": "xtls-rprx-vision"
                    }
                ],
EOF
    fi
cat >> "$xray_config" <<EOF
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "dest": "/run/nginx/ssl.sock",
                    "serverNames": [
EOF
    for ((i=0;;i++))
    do
        if ((i == ${#domain_list[@]} - 1)); then
            echo '                        "'"${domain_list[$i]}"'"' >> "$xray_config"
            break
        else
            echo '                        "'"${domain_list[$i]}"'",' >> "$xray_config"
        fi
    done
cat >> "$xray_config" <<EOF
                    ],
                    "privateKey": "${reality_private_key}",
                    "shortIds": [""]
                }
            }
EOF
    local protocol_str
    if [ "$protocol_2" -ne 0 ]; then
        [ "$protocol_2" -eq 2 ] && protocol_str="vmess" || protocol_str="vless"
cat >> "$xray_config" <<EOF
        },
        {
            "listen": "/run/xray/grpc.sock",
            "protocol": "$protocol_str",
            "settings": {
                "clients": [
                    {
                        "id": "$xid_2"
                    }
EOF
        if [ $protocol_2 -eq 2 ]; then
            echo '                ]' >> "$xray_config"
        else
            echo '                ],' >> "$xray_config"
            echo '                "decryption": "none"' >> "$xray_config"
        fi
cat >> "$xray_config" <<EOF
            },
            "streamSettings": {
                "network": "grpc",
                "grpcSettings": {
                    "serviceName": "$serviceName"
                }
            }
EOF
    fi
    if [ "$protocol_3" -ne 0 ]; then
        [ "$protocol_3" -eq 2 ] && protocol_str="vmess" || protocol_str="vless"
cat >> "$xray_config" << EOF
        },
        {
            "listen": "/run/xray/ws.sock",
            "protocol": "$protocol_str",
            "settings": {
                "clients": [
                    {
                        "id": "$xid_3"
                    }
EOF
        if [ "$protocol_3" -eq 2 ]; then
            echo '                ]' >> "$xray_config"
        else
            echo '                ],' >> "$xray_config"
            echo '                "decryption": "none"' >> "$xray_config"
        fi
cat >> "$xray_config" <<EOF
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "$path"
                }
            }
EOF
    fi
cat >> "$xray_config" <<EOF
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
// 不要修改下面一行内容
// "reality_public_key": "${reality_public_key}"
EOF
}

update_cloudreves()
{
    local i
    local need_cloudreves=0
    for i in "${pretend_list[@]}"
    do
        if [ "$i" -eq 1 ]; then
            need_cloudreves=1
            break
        fi
    done
    if [ $need_cloudreves -eq 0 ]; then
        green "当前没有域名使用到Cloudreve，不升级"
        return
    fi
    green "升级所有伪装网站的Cloudreve。。。"
    check_temp_dir
    if ! curl -Lo "${temp_dir}/cloudreve.tar.gz" "https://github.com/cloudreve/Cloudreve/releases/download/${cloudreve_version}/cloudreve_${cloudreve_version}_linux_${arch}.tar.gz"; then
        red "获取Cloudreve失败！！"
        report_bug
    fi
    if ! rm -f "${temp_dir}/cloudreve"; then
        red "路径 ${temp_dir}/cloudreve 被占用！"
        report_bug
    fi
    tar -zxf "${temp_dir}/cloudreve.tar.gz" -C "${temp_dir}" cloudreve
    local i
    local cloudreve_is_running
    for ((i = 0; i < ${#domain_list[@]}; ++i))
    do
        if [ "${pretend_list[$i]}" -ne 1 ]; then
            continue
        fi
        systemctl -q is-active "cloudreve.${true_domain_list[$i]}" && cloudreve_is_running=1 || cloudreve_is_running=0
        [ $cloudreve_is_running -eq 1 ] && systemctl stop "cloudreve.${true_domain_list[$i]}"
        cp "${temp_dir}/cloudreve" "${nginx_prefix}/html/${true_domain_list[$i]}"
        chmod +x "${nginx_prefix}/html/${true_domain_list[$i]}/cloudreve"
        if [ $cloudreve_is_running -eq 1 ]; then
            systemctl enable "${nginx_prefix}/html/${true_domain_list[$i]}/cloudreve.${true_domain_list[$i]}.service"
            systemctl start "cloudreve.${true_domain_list[$i]}"
        fi
    done
    rm -f "${temp_dir}/cloudreve"
    rm -f "${temp_dir}/cloudreve.tar.gz"
    green "Cloudreve更新完成！"
}
reset_nextcloud_host()
{
    while ! [[ -f "${nginx_prefix}/html/${true_domain_list[$1]}/config/config.php" ]]
    do
        yellow "域名 ${domain_list[$1]} 的nextcloud配置文件不存在，请先打开网站 https://${domain_list[$1]} 进行nextcloud初始化！"
        yellow "如果有疑问，请前往 https://github.com/kirin10000/Xray-script/issues 进行Bug Report"
        tyblue "完成初始化后按回车键继续。。。"
        read -rs
        echo
    done
    local new_host_string="    0 => '${domain_list[$1]}',"
    local i
    local num=1
    for ((i = 0; i < ${#domain_list[@]}; ++i))
    do
        if [ "${pretend_list[$i]}" -eq 3 ] && [ "${pretend_redirect_index_list[$i]}" -eq "$1" ]; then
            new_host_string="${new_host_string} ${num} => '${domain_list[$i]}',"
            ((++num))
        fi
    done
    local line
    line="$(awk "/'trusted_domains'/{ print NR; exit }" "${nginx_prefix}/html/${true_domain_list[$1]}/config/config.php")"
    if [ -z "$line" ]; then
        red "解析nextcloud config 出错"
        report_bug
    fi
    ((line+=2))
    check_temp_dir
    awk "{ if (NR == $line) print \"${new_host_string}\"; else print \$0}" "${nginx_prefix}/html/${true_domain_list[$1]}/config/config.php" > "${temp_dir}/temp"
    local php_is_running=0
    systemctl -q is-active php-fpm && php_is_running=1
    [ $php_is_running -ne 0 ] && systemctl stop php-fpm
    mv "${temp_dir}/temp" "${nginx_prefix}/html/${true_domain_list[$1]}/config/config.php"
    [ $php_is_running -ne 0 ] && systemctl start php-fpm && sleep 2s
}
init_web()
{
    check_temp_dir
    if [ "${pretend_list[$1]}" == "1" ]; then
        if ! curl -Lo "${temp_dir}/cloudreve.tar.gz" "https://github.com/cloudreve/Cloudreve/releases/download/${cloudreve_version}/cloudreve_${cloudreve_version}_linux_${arch}.tar.gz"; then
            red "获取cloudreve失败！"
            report_bug
        fi
        systemctl stop "cloudreve.${true_domain_list[$1]}" 2>/dev/null
        systemctl disable "cloudreve.${true_domain_list[$1]}" 2>/dev/null
        rm -rf "${nginx_prefix}/html/${true_domain_list[$1]}"
        mkdir "${nginx_prefix}/html/${true_domain_list[$1]}"
        tar -zxf "${temp_dir}/cloudreve.tar.gz" -C "${nginx_prefix}/html/${true_domain_list[$1]}" cloudreve
        chmod +x "${nginx_prefix}/html/${true_domain_list[$1]}/cloudreve"
        rm -f "${temp_dir}/cloudreve.tar.gz"
cat > "${nginx_prefix}/html/${true_domain_list[$1]}/conf.ini" << EOF
[System]
Mode = master
Debug = false

[UnixSocket]
Listen = ${nginx_prefix}/html/${true_domain_list[$1]}/cloudreve.sock
Perm = 0666
EOF
cat > "${nginx_prefix}/html/${true_domain_list[$1]}/cloudreve.${true_domain_list[$1]}.service" << EOF
[Unit]
Description=Cloudreve
Documentation=https://docs.cloudreve.org
After=network.target
After=mysqld.service
Wants=network.target

[Service]
WorkingDirectory=${nginx_prefix}/html/${true_domain_list[$1]}
ExecStart=${nginx_prefix}/html/${true_domain_list[$1]}/cloudreve
Restart=on-abnormal
RestartSec=5s
KillMode=mixed

StandardOutput=null
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOF
        local password
        password="$(timeout 3 "${nginx_prefix}/html/${true_domain_list[$1]}/cloudreve" | grep "password" | awk '{print $6}')"
        systemctl --now enable "${nginx_prefix}/html/${true_domain_list[$1]}/cloudreve.${true_domain_list[$1]}.service"
        systemctl daemon-reload
        tyblue "-------- 请打开\"https://${domain_list[$1]}\"进行Cloudreve初始化 -------"
        tyblue "  1. 登陆帐号"
        purple "    初始管理员账号：admin@cloudreve.org"
        purple "    初始管理员密码：$password"
        tyblue "  2. 右上角头像 -> 管理面板"
        tyblue "  3. 这时会弹出对话框 \"确定站点URL设置\" 选择 \"更改\""
        tyblue "  4. 左侧参数设置 -> 注册与登陆 -> 不允许新用户注册 -> 往下拉点击保存"
        sleep 15s
        echo -e "\\n\\n"
        tyblue "按两次回车键以继续。。。"
        read -rs
        echo
        read -rs
        echo
    elif [ "${pretend_list[$1]}" == "2" ]; then
        if ! curl -Lo "${temp_dir}/nextcloud.tar.bz2" "${nextcloud_url}"; then
            red "获取Nextcloud失败"
            report_bug
        fi
        rm -rf "${nginx_prefix}/html/nextcloud"
        tar -xjf "${temp_dir}/nextcloud.tar.bz2" -C "${nginx_prefix}/html"
        rm -f "${temp_dir}/nextcloud.tar.bz2"
        rm -rf "${nginx_prefix}/html/${true_domain_list[$1]}"
        mv "${nginx_prefix}/html/nextcloud" "${nginx_prefix}/html/${true_domain_list[$1]}"
        chown -R www-data:www-data "${nginx_prefix}/html/${true_domain_list[$1]}"
        systemctl enable php-fpm
        systemctl start php-fpm
        echo -e "\\n\\n"
        yellow "请尽快打开\"https://${domain_list[$1]}\"进行Nextcloud初始化设置："
        tyblue " 1. 初始化管理员用户名和密码"
        tyblue " 2. 数据库类型选择SQLite"
        tyblue " 3. 不建议勾选\"安装推荐的应用\"，初始化完成后还能安装"
        sleep 15s
        echo -e "\\n\\n"
        tyblue "按两次回车键以继续。。。"
        read -rs
        echo
        read -rs
        echo
        for ((i = 0; i < ${#domain_list[@]}; ++i))
        do
            if [ "${pretend_list[$i]}" -eq 3 ] && [ "${pretend_redirect_index_list[$i]}" -eq "$1" ]; then
                # 此域名正在被别的域名重定向
                reset_nextcloud_host "$1"
                break
            fi
        done
    elif [ "${pretend_list[$1]}" == "3" ]; then
        local redirect="${pretend_redirect_index_list[$1]}"
        if [ "${pretend_list[$redirect]}" -eq 2 ]; then
            reset_nextcloud_host "$redirect"
        fi
    fi
}

print_config_info()
{
    echo -e "\\n\\n\\n"
    if [ $protocol_1 -ne 0 ]; then
        tyblue "--------------------- VLESS-TCP-REALITY (不走CDN) ---------------------"
        tyblue " protocol(传输协议)    ：\\033[33mvless"
        purple "  (V2RayN选择\"添加[VLESS]服务器\";V2RayNG选择\"手动输入[VLESS]\")"
        tyblue " address(地址)         ：\\033[33m服务器ip"
        tyblue " port(端口)            ：\\033[33m443"
        tyblue " id(用户ID/UUID)       ：\\033[33m${xid_1}"
        tyblue " flow(流控)            ：\\033[33mxtls-rprx-vision"
        tyblue " encryption(加密)      ：\\033[33mnone"
        tyblue " ---Transport/StreamSettings(底层传输方式/流设置)---"
        tyblue "  network(传输方式)             ：\\033[33mtcp"
        purple "   (Shadowrocket传输方式选none)"
        tyblue "  type(伪装类型)                ：\\033[33mnone"
        tyblue "  security(传输层加密)          ：\\033[33mreality"
        purple "   (V2RayN(G):底层传输安全)"
        if [ ${#domain_list[@]} -eq 1 ]; then
            tyblue "  serverName                    ：\\033[33m${domain_list[*]}"
        else
            tyblue "  serverName                    ：\\033[33m${domain_list[*]} \\033[35m(任选其一)"
        fi
        purple "   (V2RayN(G):SNI;Shadowrocket:Peer 名称)"
        tyblue "  fingerprint                   ：\\033[33m空\\033[36m/\\033[33mchrome\\033[32m(推荐)\\033[36m/\\033[33mfirefox\\033[36m/\\033[33mios\\033[36m/\\033[33msafari\\033[36m/\\033[33mandroid\\033[36m/\\033[33medge\\033[36m/\\033[33m360\\033[36m/\\033[33mqq\\033[36m/\\033[33mrandom"
        purple "                                    (此选项决定是否伪造浏览器指纹：空代表不伪造，使用GO程序默认指纹；random代表随机选择一种浏览器伪造指纹)"
        purple "  publicKey                     ：\\033[33m${reality_public_key}"
        purple "  shortId                       ：\\033[33m空"
        purple "  spiderX                       ：\\033[33m空"
        tyblue " ------------------------其他-----------------------"
        tyblue "  Mux(多路复用)                 ：建议关闭"
        purple "   (V2RayN:设置页面-开启Mux多路复用)"
        tyblue "------------------------------------------------------------------------"
    fi
    if [ $protocol_2 -ne 0 ]; then
        echo
        if [ $protocol_2 -eq 1 ]; then
            tyblue "---------------- VLESS-gRPC-TLS (有CDN则走CDN，否则直连) ---------------"
            tyblue " protocol(传输协议)    ：\\033[33mvless"
            purple "  (V2RayN选择\"添加[VLESS]服务器\";V2RayNG选择\"手动输入[VLESS]\")"
        else
            tyblue "---------------- VMess-gRPC-TLS (有CDN则走CDN，否则直连) ---------------"
            tyblue " protocol(传输协议)    ：\\033[33mvmess"
            purple "  (V2RayN选择\"添加[VMess]服务器\";V2RayNG选择\"手动输入[Vmess]\")"
        fi
        if [ ${#domain_list[@]} -eq 1 ]; then
            tyblue " address(地址)         ：\\033[33m${domain_list[*]}"
        else
            tyblue " address(地址)         ：\\033[33m${domain_list[*]} \\033[35m(任选其一)"
        fi
        purple "  (Qv2ray:主机)"
        tyblue " port(端口)            ：\\033[33m443"
        tyblue " id(用户ID/UUID)       ：\\033[33m${xid_2}"
        if [ $protocol_2 -eq 1 ]; then
            tyblue " flow(流控)            ：\\033[33m空"
            tyblue " encryption(加密)      ：\\033[33mnone"
        else
            tyblue " security(加密方式)    ：使用CDN，推荐\\033[33mauto\\033[36m;不使用CDN，推荐\\033[33mnone"
            purple "  (Qv2ray:安全选项;Shadowrocket:算法)"
        fi
        tyblue " ---Transport/StreamSettings(底层传输方式/流设置)---"
        tyblue "  network(传输方式)             ：\\033[33mgrpc"
        tyblue "  serviceName                   ：\\033[33m${serviceName}"
        tyblue "  multiMode                     ：\\033[33mtrue"
        purple "   (V2RayN(G)伪装类型(type)选择multi"
        tyblue "  security(传输层加密)          ：\\033[33mtls"
        purple "   (V2RayN(G):底层传输安全;Qv2ray:TLS设置-安全类型)"
        tyblue "  serverName                    ：\\033[33m空"
        purple "   (V2RayN(G):SNI和伪装域名;Qv2ray:TLS设置-服务器地址;Shadowrocket:Peer 名称)"
        tyblue "  allowInsecure                 ：\\033[33mfalse"
        purple "   (Qv2ray:TLS设置-允许不安全的证书(不打勾);Shadowrocket:允许不安全(关闭))"
        tyblue "  fingerprint                   ：\\033[33m空\\033[36m/\\033[33mchrome\\033[32m(推荐)\\033[36m/\\033[33mfirefox\\033[36m/\\033[33msafari"
        purple "                                           (此选项决定是否伪造浏览器指纹，空代表不伪造)"
        tyblue "  alpn                          ：建议设置为\\033[33mh2,http/1.1 \\033[35m(此选项为空/未配置时，默认值为\"h2,http/1.1\")"
        purple "   (Qv2ray:TLS设置-ALPN) (注意Qv2ray如果要设置alpn为h2,http/1.1，请填写\"h2|http/1.1\")"
        tyblue " ------------------------其他-----------------------"
        tyblue "  Mux(多路复用)                 ：强烈建议关闭"
        purple "   (V2RayN:设置页面-开启Mux多路复用)"
        tyblue "------------------------------------------------------------------------"
    fi
    if [ $protocol_3 -ne 0 ]; then
        echo
        if [ $protocol_3 -eq 1 ]; then
            tyblue "------------- VLESS-WebSocket-TLS (有CDN则走CDN，否则直连) -------------"
            tyblue " protocol(传输协议)    ：\\033[33mvless"
            purple "  (V2RayN选择\"添加[VLESS]服务器\";V2RayNG选择\"手动输入[VLESS]\")"
        else
            tyblue "------------- VMess-WebSocket-TLS (有CDN则走CDN，否则直连) -------------"
            tyblue " protocol(传输协议)    ：\\033[33mvmess"
            purple "  (V2RayN选择\"添加[VMess]服务器\";V2RayNG选择\"手动输入[Vmess]\")"
        fi
        if [ ${#domain_list[@]} -eq 1 ]; then
            tyblue " address(地址)         ：\\033[33m${domain_list[*]}"
        else
            tyblue " address(地址)         ：\\033[33m${domain_list[*]} \\033[35m(任选其一)"
        fi
        purple "  (Qv2ray:主机)"
        tyblue " port(端口)            ：\\033[33m443"
        tyblue " id(用户ID/UUID)       ：\\033[33m${xid_3}"
        if [ $protocol_3 -eq 1 ]; then
            tyblue " flow(流控)            ：\\033[33m空"
            tyblue " encryption(加密)      ：\\033[33mnone"
        else
            tyblue " security(加密方式)    ：使用CDN，推荐\\033[33mauto\\033[36m;不使用CDN，推荐\\033[33mnone"
            purple "  (Qv2ray:安全选项;Shadowrocket:算法)"
        fi
        tyblue " ---Transport/StreamSettings(底层传输方式/流设置)---"
        tyblue "  network(传输方式)             ：\\033[33mws"
        purple "   (Shadowrocket传输方式选websocket)"
        tyblue "  path(路径)                    ：\\033[33m${path}?ed=2048"
        tyblue "  Host                          ：\\033[33m空"
        purple "   (V2RayN(G):伪装域名;Qv2ray:协议设置-请求头)"
        tyblue "  security(传输层加密)          ：\\033[33mtls"
        purple "   (V2RayN(G):底层传输安全;Qv2ray:TLS设置-安全类型)"
        tyblue "  serverName                    ：\\033[33m空"
        purple "   (V2RayN(G):SNI和伪装域名;Qv2ray:TLS设置-服务器地址;Shadowrocket:Peer 名称)"
        tyblue "  allowInsecure                 ：\\033[33mfalse"
        purple "   (Qv2ray:TLS设置-允许不安全的证书(不打勾);Shadowrocket:允许不安全(关闭))"
        tyblue "  fingerprint                   ：\\033[33m空\\033[32m(推荐)\\033[36m/\\033[33mchrome\\033[36m/\\033[33mfirefox\\033[36m/\\033[33msafari"
        purple "                                           (此选项决定是否伪造浏览器指纹，空代表不伪造)"
        tyblue "  alpn                          ：此参数不生效，可随意设置 \\033[35m(Websocket模式下alpn将被固定为\"http/1.1\")"
        tyblue " ------------------------其他-----------------------"
        tyblue "  Mux(多路复用)                 ：建议关闭"
        purple "   (V2RayN:设置页面-开启Mux多路复用)"
        tyblue "------------------------------------------------------------------------"
    fi
    echo
    tyblue " 请使用客户端Xray版本 v1.8.3+"
    echo
    tyblue " 脚本最后更新时间：2023.6.23"
    echo
    red    " 声明：此脚本仅供交流学习使用，请勿使用此脚本行违法之事！网络非法外之地，行非法之事，必将接受法律制裁！"
    tyblue " 2023.6"
}

install_update_xray_reality_web()
{
    in_install_update_xray_reality_web=1
    remove_nginx_system
    remove_php_system
    check_SELinux
    check_install_dependency iproute2 iproute
    check_port
    check_install_dependency ca-certificates ca-certificates
    check_install_dependency curl curl
    check_install_dependency procps procps-ng
    install_epel
    install_remi
    update_script
    check_ssh_timeout
    uninstall_firewall
    doupdate
    enter_temp_dir
    install_bbr

    #读取信息
    local old_true_domain_list=("${true_domain_list[@]}")
    if [ $update -eq 0 ]; then
        clear_config
        readProtocolConfig
        readDomain
    fi

    local choice

    local install_php
    if [ $update -eq 0 ]; then
        [ "${pretend_list[0]}" == "2" ] && install_php=1 || install_php=0
    else
        install_php=$php_is_installed
    fi
    local use_existed_php=0
    if [ $install_php -eq 1 ]; then
        if [ $update -eq 1 ]; then
            if check_php_update; then
                ! ask_if "检测到php有新版本，是否更新?(y/n)" && use_existed_php=1
            else
                green "php已经是最新版本，不更新"
                use_existed_php=1
            fi
        elif [ $php_is_installed -eq 1 ]; then
            tyblue "---------------检测到php已存在---------------"
            tyblue " 1. 使用现有php"
            tyblue " 2. 卸载现有php并重新编译安装"
            echo
            choice=""
            while [ "$choice" != "1" ] && [ "$choice" != "2" ]
            do
                read -rp "您的选择是：" choice
            done
            [ $choice -eq 1 ] && use_existed_php=1
        fi
    fi

    local use_existed_nginx=0
    if [ $update -eq 1 ]; then
        if check_nginx_update; then
            ! ask_if "检测到Nginx有新版本，是否更新?(y/n)" && use_existed_nginx=1
        else
            green "Nginx已经是最新版本，不更新"
            use_existed_nginx=1
        fi
    elif [ $nginx_is_installed -eq 1 ]; then
        tyblue "---------------检测到Nginx已存在---------------"
        tyblue " 1. 使用现有Nginx"
        tyblue " 2. 卸载现有Nginx并重新编译安装"
        echo
        choice=""
        while [ "$choice" != "1" ] && [ "$choice" != "2" ]
        do
            read -rp "您的选择是：" choice
        done
        [ $choice -eq 1 ] && use_existed_nginx=1
    fi

    if [ $update -eq 0 ]; then
        green "即将开始安装Xray-REALITY+Web，可能需要10-20分钟。。。"
    else
        green "即将开始更新Xray-REALITY+Web，可能需要10-20分钟。。。"
    fi
    sleep 3s

    # 安装所有依赖
    [ $use_existed_nginx -eq 0 ] && install_nginx_compile_toolchains
    install_nginx_dependencies
    if [ $install_php -eq 1 ]; then
        [ $use_existed_php -eq 0 ] && install_php_compile_toolchains
        install_php_dependencies
    fi
    install_acme_dependencies
    if [ $update -eq 0 ]; then
        install_web_dependencies ""
    else
        for pretend in "${pretend_list[@]}"
        do
            if [ $pretend -eq 1 ]; then
                install_web_dependencies "1"
            fi
        done
    fi

    #编译&&安装php
    # 运这段代码后，若是：
    # 安装Xray-REALITY+Web            ： php停止运行、禁用服务
    # 更新/重新安装Xray-REALITY+Web   ： PHP运行、启动状态保持不变
    if [ $install_php -eq 1 ]; then
        local php_is_running=0
        local php_is_enabled=0
        if [ ${#old_true_domain_list[@]} -ne 0 ]; then
            systemctl -q is-active php-fpm && php_is_running=1
            systemctl -q is-enabled php-fpm 2> /dev/null && php_is_enabled=1
        fi
        if [ $use_existed_php -eq 0 ]; then
            compile_php
            remove_php
            install_php_part1
        else
            systemctl stop php-fpm
            systemctl disable php-fpm
        fi
        install_php_part2
        if [ ${#old_true_domain_list[@]} -ne 0 ]; then
            [ $php_is_running -eq 1 ] && systemctl start php-fpm && sleep 2s
            [ $php_is_enabled -eq 1 ] && systemctl enable php-fpm
        fi
    elif [ ${#old_true_domain_list[@]} -eq 0 ]; then
        # 新安装Xray-REALITY+Web，且不需要PHP
        systemctl stop php-fpm 2> /dev/null
        systemctl disable php-fpm 2> /dev/null
    fi

    #编译&&安装Nginx
    # 运行完这段代码后：
    #                     PHP将被停止、禁用
    # 安装/重新安装  ：   cloudreve将被全部停止、禁用、删除
    # 更新           ：   cloudreve将被全部停止、禁用
    if [ $use_existed_nginx -eq 0 ]; then
        compile_nginx
        if [ $update -eq 1 ]; then
            backup_remove_nginx_webs
        else
            remove_nginx_webs
        fi
        install_nginx_part1
    else
        systemctl stop nginx
        systemctl disable nginx
        systemctl stop php-fpm 2> /dev/null
        systemctl disable php-fpm 2> /dev/null
        if [ $update -eq 0 ]; then
            disable_all_cloudreves
            local domain
            for domain in "${old_true_domain_list[@]}"
            do
                rm -rf "${nginx_prefix}/html/${domain}"
            done
            systemctl daemon-reload
        fi
        rm -rf "${nginx_prefix}/conf.d"
        rm -rf "${nginx_prefix}/certs"
        rm -rf "${nginx_prefix}/html/issue_certs"
        rm -rf "${nginx_prefix}/conf/issue_certs.conf"
        cp "${nginx_prefix}/conf/nginx.conf.default" "${nginx_prefix}/conf/nginx.conf"
        nginx_is_installed=0
        is_installed=0
    fi
    install_nginx_part2
    [ $update -eq 1 ] && [ $use_existed_nginx -eq 0 ] && restore_webs

    #安装Xray
    remove_xray
    install_update_xray

    if [ $update -eq 0 ]; then
        [ -e "$HOME/.acme.sh/acme.sh" ] && "$HOME/.acme.sh/acme.sh" --uninstall
        rm -rf "$HOME/.acme.sh"
        local src
        if ! src="$(curl -L https://get.acme.sh)" || ! sh <(echo "$src"); then
            red "acme.sh 安装失败！"
            report_bug
        fi
        "$HOME/.acme.sh/acme.sh" --register-account -ak ec-256 --server zerossl -m "my@example.com"

        gen_reality_key
    fi
    "$HOME/.acme.sh/acme.sh" --upgrade --auto-upgrade
    get_all_certs

    #配置Nginx和Xray
    config_nginx
    config_xray
    systemctl restart xray nginx
    if [ $update -eq 0 ]; then
        init_web 0
        green "-------------------安装完成-------------------"
        print_config_info
    else
        check_need_php && systemctl --now enable php-fpm
        update_cloudreves
        local i
        for ((i = 0; i < ${#domain_list[@]}; ++i))
        do
            [ "${pretend_list[$i]}" -eq 1 ] && systemctl --now enable "${nginx_prefix}/html/${true_domain_list[$i]}/cloudreve.${true_domain_list[$i]}.service"
        done
        green "-------------------更新完成-------------------"
    fi
    cd /
    rm -rf "$temp_dir"
    in_install_update_xray_reality_web=0
}

show_running_status()
{
    # 运行信息
    local xray_is_running
    local xray_is_enabled
    local nginx_is_running
    local nginx_is_enabled
    local php_is_running
    local php_is_enabled
    local cloudreve_running_list
    local cloudreve_enabled_list
    xray_is_running=0
    xray_is_enabled=0
    if [ $xray_is_installed -eq 1 ]; then
        systemctl -q is-active xray && xray_is_running=1
        systemctl -q is-enabled xray && xray_is_enabled=1
    fi
    nginx_is_running=0
    nginx_is_enabled=0
    if [ $nginx_is_installed -eq 1 ]; then
        systemctl -q is-active nginx && nginx_is_running=1
        systemctl -q is-enabled nginx && nginx_is_enabled=1
    fi
    php_is_running=0
    php_is_enabled=0
    if [ $php_is_installed -eq 1 ]; then
        systemctl -q is-active php-fpm && php_is_running=1
        systemctl -q is-enabled php-fpm && php_is_enabled=1
    fi
    local i
    for ((i = 0; i < ${#domain_list[@]}; ++i))
    do
        if [ "${pretend_list[$i]}" -ne 1 ]; then
            cloudreve_running_list+=("")
            cloudreve_enabled_list+=("")
        else
            if systemctl -q is-active "cloudreve.${true_domain_list[$i]}.service"; then
                cloudreve_running_list+=(1)
            else
                cloudreve_running_list+=(0)
            fi
            if systemctl -q is-enabled "cloudreve.${true_domain_list[$i]}.service" 2> /dev/null; then
                cloudreve_enabled_list+=(1)
            else
                cloudreve_enabled_list+=(0)
            fi
        fi
    done
    local temp_str
    gen_runstatus_str()
    {
        temp_str=""
        [ "$1" -ne 0 ] && temp_str="${temp_str}\\033[32m已安装" || temp_str="${temp_str}\\033[31m未安装"
        temp_str="${temp_str}            "
        [ "$2" -ne 0 ] && temp_str="${temp_str}\\033[32m运行中" || temp_str="${temp_str}\\033[31m未运行"
        temp_str="${temp_str}            "
        [ "$3" -ne 0 ] && temp_str="${temp_str}\\033[32m已启用" || temp_str="${temp_str}\\033[31m未启用"
    }
    tyblue "------------ 运行状态 ----------"
    gen_runstatus_str $xray_is_installed $xray_is_running $xray_is_enabled
    tyblue  " Xray :      $temp_str"
    gen_runstatus_str $nginx_is_installed $nginx_is_running $nginx_is_enabled
    tyblue  " Nginx:      $temp_str"
    gen_runstatus_str $php_is_installed $php_is_running $php_is_enabled
    tyblue  " PHP  :      $temp_str"
    local domain
    for ((i = 0; i < ${#domain_list[@]}; ++i))
    do
        if [ "${pretend_list[$i]}" -eq 1 ]; then
            domain="${domain_list[$i]}"
            [ ${domain_config_list[$i]} -eq 1 ] && domain="${domain} ${true_domain_list[$i]}"
            gen_runstatus_str 1 ${cloudreve_running_list[$i]} ${cloudreve_enabled_list[$i]}
            tyblue "Cloudreve ($domain):    $temp_str"
        fi
    done
}

restart_xray_reality_web()
{
    config_check
    local err=0
    systemctl stop xray
    systemctl disable xray
    if ! systemctl --now enable xray; then
        red "Xray 启动失败！"
        err=1
    fi
    systemctl stop nginx
    systemctl disable nginx
    if ! systemctl --now enable nginx; then
        red "Nginx 启动失败！"
        err=1
    fi
    systemctl stop php-fpm 2> /dev/null
    systemctl disable php-fpm 2> /dev/null
    if check_need_php && ! systemctl --now enable php-fpm; then
        red "PHP 启动失败！"
        err=1
    fi
    local i
    local domain_str
    for ((i = 0; i < ${#domain_list[@]}; ++i))
    do
        if [ "${pretend_list[$i]}" -eq 1 ]; then
            systemctl stop "cloudreve.${true_domain_list[$i]}" 2> /dev/null
            systemctl disable "cloudreve.${true_domain_list[$i]}" 2> /dev/null
            if ! systemctl --now enable "${nginx_prefix}/html/${true_domain_list[$i]}/cloudreve.${true_domain_list[$i]}.service"; then
                if [ "${domain_config_list[$i]}" -eq 1 ]; then
                    domain_str="${domain_list[$i]} ${true_domain_list[$i]}"
                else
                    domain_str="${domain_list[$i]}"
                fi
                red "Cloudreve(${domain_str}) 启动/重启失败！"
                err=1
            fi
        fi
    done
    sleep 2s
    if ! systemctl -q is-active xray; then
        red "Xray 启动失败！"
        err=1
    fi
    if ! systemctl -q is-active nginx; then
        red "Nginx 启动失败！"
        err=1
    fi
    if check_need_php && ! systemctl -q is-active php-fpm; then
        red "PHP 启动失败！"
        err=1
    fi
    for ((i = 0; i < ${#domain_list[@]}; ++i))
    do
        if [ "${pretend_list[$i]}" -eq 1 ] && ! systemctl -q is-active "cloudreve.${true_domain_list[$i]}"; then
            if [ "${domain_config_list[$i]}" -eq 1 ]; then
                domain_str="${domain_list[$i]} ${true_domain_list[$i]}"
            else
                domain_str="${domain_list[$i]}"
            fi
            red "Cloudreve(${domain_str}) 启动失败！"
            err=1
        fi
    done
    if [ $err -eq 0 ]; then
        green "Xray-REALITY+Web 启动/重启成功！"
    else
        red "Xray-REALITY+Web 启动失败，请尝试重置域名/重新安装！"
        report_bug
    fi
}
disable_xray_reality_web()
{
    systemctl stop nginx 2> /dev/null
    systemctl disable nginx 2> /dev/null
    systemctl stop xray 2> /dev/null
    systemctl disable xray 2> /dev/null
    systemctl stop php-fpm 2> /dev/null
    systemctl disable php-fpm 2> /dev/null
    disable_all_cloudreves
    tyblue "Xray-REALITY+Web 已停止并禁用"
}

config_check()
{
    if [ $is_installed -eq 0 ]; then
        red "尚未安装Xray-REALITY+Web，请先安装"
        exit 0
    fi
    if [ -z "$reality_private_key" ]; then
        yellow "当前配置不自洽，请重新安装"
        exit 0
    fi
}

full_install_php()
{
    check_temp_dir
    green "开始安装/更新php。。。"
    sleep 3s
    install_php_compile_toolchains
    install_php_dependencies
    compile_php
    remove_php
    install_php_part1
    install_php_part2
}
update_nginx()
{
    if [ $nginx_is_installed -eq 0 ]; then
        yellow "Nginx 尚未安装，请选择 安装 Xray-REALITY+Web ！"
        exit 0
    fi
    check_install_dependency curl curl
    check_install_dependency ca-certificates ca-certificates
    update_script
    if ! check_nginx_update; then
        green "Nginx 已是最新版本！"
        exit 0
    else
        green "Nginx有新版本"
        ! ask_if "是否更新？(y/n)" && exit 0
    fi
    in_install_update_xray_reality_web=1
    remove_nginx_system
    check_SELinux
    check_install_dependency procps procps-ng
    install_epel
    install_remi
    check_ssh_timeout
    in_install_update_xray_reality_web=0
    install_nginx_compile_toolchains
    install_nginx_dependencies
    enter_temp_dir
    compile_nginx
    local nginx_is_running=0
    local nginx_is_enabled=0
    systemctl -q is-active nginx && nginx_is_running=1
    systemctl -q is-enabled nginx && nginx_is_enabled=1
    backup_remove_nginx_webs
    install_nginx_part1
    install_nginx_part2
    restore_webs
    config_nginx
    get_all_certs
    if [ $nginx_is_running -eq 1 ]; then
        systemctl restart nginx
    else
        systemctl stop nginx
    fi
    [ $nginx_is_enabled -eq 0 ] && systemctl disable nginx
    cd /
    rm -rf "$temp_dir"
    green "Nginx更新完成！"
}
install_update_php()
{
    check_install_dependency curl curl
    check_install_dependency ca-certificates ca-certificates
    update_script
    local php_is_running=0
    local php_is_enabled=0
    if [ $php_is_installed -eq 1 ]; then
        if ! check_php_update; then
            green "PHP已是最新版本！"
            exit 0
        else
            green "PHP有新版本！"
            ! ask_if "是否更新？(y/n)" && exit 0
        fi
        systemctl -q is-active php-fpm && php_is_running=1
        systemctl -q is-enabled php-fpm && php_is_enabled=1
    else
        if { { [ "$distro" == centos ] || [ "$distro" == centos-stream ] || [ "$distro" == oracle ] || [ "$distro" == rhel ]; } && ! version_ge "$system_version" "8"; } || { [ "$distro" == "fedora" ] && ! version_ge "$system_version" "32"; } || { [ "$distro" == "ubuntu" ] && ! version_ge "$system_version" "20.04"; } || { [ "$distro" == "debian" ] && ! version_ge "$system_version" 11; }; then
            red "系统版本过低，无法安装php！"
            echo
            yellow "支持在以下版本系统下安装php："
            yellow " 1. Ubuntu 20.04+"
            yellow " 2. Debian 11+"
            yellow " 3. 其他以 Debian 11+ 为基的系统"
            yellow " 4. Red Hat Enterprise Linux 8+"
            yellow " 5. CentOS 8+"
            yellow " 6. Fedora 32+"
            yellow " 7. Oracle Linux 8+"
            yellow " 8. 其他以 Red Hat 8+ 为基的系统"
            exit 0
        elif [ "$distro" == unknow ]; then
            yellow "警告：未知的系统，可能导致php安装失败！"
            echo
            yellow "支持在以下版本系统下安装php："
            yellow " 1. Ubuntu 20.04+"
            yellow " 2. Debian 11+"
            yellow " 3. 其他以 Debian 11+ 为基的系统"
            yellow " 4. Red Hat Enterprise Linux 8+"
            yellow " 5. CentOS 8+"
            yellow " 6. Fedora 32+"
            yellow " 7. Oracle Linux 8+"
            yellow " 8. 其他以 Red Hat 8+ 为基的系统"
            echo
        else
            tyblue "尚未安装PHP！"
        fi
        ! ask_if "是否进行安装？(y/n)" && exit 0
    fi
    in_install_update_xray_reality_web=1
    remove_php_system
    check_SELinux
    check_install_dependency procps procps-ng
    install_epel
    install_remi
    check_ssh_timeout
    in_install_update_xray_reality_web=0
    enter_temp_dir
    full_install_php
    cd /
    rm -rf "$temp_dir"
    [ $php_is_enabled -eq 1 ] && systemctl enable php-fpm
    [ $php_is_running -eq 1 ] && systemctl start php-fpm
    green "PHP安装/更新完成！"
}
reinit_domain()
{
    config_check
    yellow "重置域名将删除所有现有域名(包括域名证书、伪装网站等)"
    ! ask_if "是否继续？(y/n)" && exit 0
    check_install_dependency ca-certificates ca-certificates
    check_install_dependency curl curl
    update_script
    green "开始重置域名。。。"
    # check port?
    install_acme_dependencies
    local old_true_domain_list=("${true_domain_list[@]}")
    unset domain_list
    unset true_domain_list
    unset domain_config_list
    unset pretend_list
    unset pretend_redirect_list
    unset pretend_redirect_index_list
    readDomain
    local has_enter_temp_dir=0
    if [ "${pretend_list[0]}" -eq 2 ] && [ "$php_is_installed" -eq 0 ]; then
        check_SELinux
        check_install_dependency procps procps-ng
        install_epel
        install_web_dependencies 2
        in_install_update_xray_reality_web=1
        check_ssh_timeout
        in_install_update_xray_reality_web=0
        enter_temp_dir
        has_enter_temp_dir=1
        full_install_php
    else
        install_web_dependencies "${pretend_list[0]}"
        systemctl stop php-fpm 2> /dev/null
        systemctl disable php-fpm 2> /dev/null
    fi
    if [ -f "$HOME/.acme.sh/acme.sh" ]; then
        "$HOME/.acme.sh/acme.sh" --uninstall
    else
        yellow "警告：文件 $HOME/.acme.sh/acme.sh 不存在，可能已经被您删除！"
    fi
    rm -rf "$HOME/.acme.sh"
    local src
    if ! src="$(curl -L https://get.acme.sh)" || ! sh <(echo "$src"); then
        red "acme.sh 安装失败！"
        report_bug
    fi
    "$HOME/.acme.sh/acme.sh" --register-account -ak ec-256 --server zerossl -m "my@example.com"
    "$HOME/.acme.sh/acme.sh --upgrade --auto-upgrade"
    disable_all_cloudreves
    systemctl stop nginx
    systemctl disable nginx
    local domain
    for domain in "${old_true_domain_list[@]}"
    do
        rm -rf "${nginx_prefix}/html/${domain}"
    done
    systemctl daemon-reload
    rm -rf "${nginx_prefix}/conf.d"
    rm -rf "${nginx_prefix}/certs"
    rm -rf "${nginx_prefix}/html/issue_certs"
    rm -rf "${nginx_prefix}/conf/issue_certs.conf"
    cp "${nginx_prefix}/conf/nginx.conf.default" "${nginx_prefix}/conf/nginx.conf"
    nginx_is_installed=0
    is_installed=0
    install_nginx_part2
    get_all_certs
    config_nginx
    config_xray
    systemctl restart nginx xray
    systemctl enable xray
    sleep 2s
    [ $has_enter_temp_dir -eq 0 ] && enter_temp_dir
    init_web 0
    cd /
    rm -rf "$temp_dir"
    green "域名重置完成！"
    print_config_info
}
add_domain()
{
    config_check
    if ! systemctl -q is-active xray || ! systemctl -q is-active nginx; then
        # 初始化网盘需要打开网站页面，这需要Nginx和Xray都在运行
        yellow "请先启动 Xray-REALITY+Web !"
        exit 0
    fi
    check_install_dependency curl curl
    check_install_dependency ca-certificates ca-certificates
    update_script
    # check port?
    readDomain
    local i=$((${#pretend_list[@]} - 1))
    local has_enter_temp_dir=0
    if [ "${pretend_list[$i]}" -eq 2 ] && [ $php_is_installed -eq 0 ]; then
        check_SELinux
        check_install_dependency procps procps-ng
        install_epel
        install_web_dependencies 2
        in_install_update_xray_reality_web=1
        check_ssh_timeout
        in_install_update_xray_reality_web=0
        enter_temp_dir
        has_enter_temp_dir=1
        full_install_php
    else
        install_web_dependencies "${pretend_list[$i]}"
    fi
    if ! get_cert $i; then
        systemctl restart nginx
        red "申请证书失败！！"
        red "域名添加失败"
        exit 1
    fi
    config_nginx
    config_xray
    systemctl restart nginx xray
    sleep 2s
    [ $has_enter_temp_dir -eq 0 ] && enter_temp_dir
    init_web $i
    cd /
    rm -rf "$temp_dir"
    green "域名添加完成！！"
    print_config_info
}
delete_domain()
{
    config_check
    if [ ${#domain_list[@]} -le 1 ]; then
        yellow "当前只有一个域名！"
        exit 1
    fi
    local selected_domain_index
    if ! select_domain "请选择需要删除的域名"; then
        exit 0
    fi
    local i
    for ((i = 0; i < ${#domain_list[@]}; ++i))
    do
        if [ "${pretend_redirect_index_list[$i]}" -eq "$selected_domain_index" ]; then
            red "域名 ${domain_list[$i]} 伪装网站正重定向至当前域名，无法删除当前域名！"
            exit 1
        fi
    done
    local nginx_is_running
    systemctl -q is-active nginx && nginx_is_running=1 || nginx_is_running=0
    [ $nginx_is_running -eq 1 ] && systemctl stop nginx
    rm -f "${nginx_prefix}/certs/${true_domain_list[$selected_domain_index]}.key"
    rm -f "${nginx_prefix}/certs/${true_domain_list[$selected_domain_index]}.cer"
    "$HOME/.acme.sh/acme.sh" --remove --domain "${true_domain_list[$selected_domain_index]}" --ecc
    rm -rf "$HOME/.acme.sh/${true_domain_list[$selected_domain_index]}_ecc"
    systemctl stop "cloudreve.${true_domain_list[$selected_domain_index]}" 2> /dev/null
    systemctl disable "cloudreve.${true_domain_list[$selected_domain_index]}" 2> /dev/null
    local _redirect=""
    if [ "${pretend_list[$selected_domain_index]}" -eq 3 ]; then
        _redirect="${pretend_redirect_index_list[$selected_domain_index]}"
        [ "${pretend_list[$_redirect]}" -ne 2 ] && _redirect=""
    fi
    rm -rf "${nginx_prefix}/html/${true_domain_list[$selected_domain_index]}"
    systemctl daemon-reload
    unset 'domain_list[$selected_domain_index]'
    unset 'true_domain_list[$selected_domain_index]'
    unset 'domain_config_list[$selected_domain_index]'
    unset 'pretend_list[$selected_domain_index]'
    unset 'pretend_redirect_list[$selected_domain_index]'
    unset 'pretend_redirect_index_list[$selected_domain_index]'
    domain_list=("${domain_list[@]}")
    true_domain_list=("${true_domain_list[@]}")
    domain_config_list=("${domain_config_list[@]}")
    pretend_list=("${pretend_list[@]}")
    pretend_redirect_list=("${pretend_list[@]}")
    pretend_redirect_index_list=("${pretend_list[@]}")
    config_nginx
    config_xray
    [ -n "$_redirect" ] && reset_nextcloud_host "$_redirect"
    systemctl -q is-active xray && systemctl restart xray
    [ $nginx_is_running -eq 1 ] && systemctl start nginx
    if ! check_need_php; then
        systemctl stop php-fpm
        systemctl disable php-fpm
    fi
    green "域名删除完成！！"
    print_config_info
}
change_pretend()
{
    config_check
    if ! systemctl -q is-active xray || ! systemctl -q is-active nginx; then
        # 初始化网盘需要打开网站页面，这需要Nginx和Xray都在运行
        yellow "请先启动 Xray-REALITY+Web !"
        exit 0
    fi
    tyblue "------------------ 当前域名伪装网站 -----------------"
    local str
    local i
    for ((i = 0; i < ${#domain_list[@]}; ++i))
    do
        str="${domain_list[$i]}"
        if [ "${domain_config_list[$i]}" -eq 1 ]; then
            str="${str},${true_domain_list[$i]}"
        fi
        str="$str :"
        if [ "${pretend_list[$i]}" -eq 1 ]; then
            str="$str Cloudreve"
        elif [ "${pretend_list[$i]}" -eq 2 ]; then
            str="$str Nextcloud"
        else
            str="$str 重定向至 "
            if [ "${domain_config_list[${pretend_redirect_index_list[$i]}]}" -eq 1 ]; then
                str="${str}${domain_list[${pretend_redirect_index_list[$i]}]},${true_domain_list[${pretend_redirect_index_list[$i]}]}"
            else
                str="${str}${domain_list[${pretend_redirect_index_list[$i]}]}"
            fi
        fi
        tyblue "$str"
    done
    echo
    local selected_domain_index
    ! select_domain "请选择需要修改伪装网站类型的域名" && exit 0
    local pretend
    local pretend_redirect
    local pretend_redirect_index
    readPretend $selected_domain_index
    if [ "$pretend" -eq 3 ]; then
        if [ "${pretend_list[$selected_domain_index]}" -le 2 ]; then
            # 从非重定向改至重定向
            for ((i = 0; i < ${#domain_list[@]}; ++i))
            do
                if [ "${pretend_list[$i]}" -eq 3 ] && [ "${pretend_redirect_index_list[$i]}" -eq $selected_domain_index ]; then
                    yellow "该域名伪装网站正在被其他域名重定向，不可修改至重定向！"
                    exit 0
                fi
            done
        fi
    fi
    if [ "$pretend" -eq "${pretend_list[$selected_domain_index]}" ]; then
        if [ "$pretend" -ne 3 ] || [ "${pretend_redirect_list[$selected_domain_index]}" == "${pretend_redirect}" ]; then
            tyblue "伪装类型尚未改变！"
            exit 0
        fi
    fi
    # 安装PHP 及 依赖
    local has_enter_temp_dir=0
    if [ "$pretend" -eq 2 ] && [ $php_is_installed -eq 0 ]; then
        check_SELinux
        check_install_dependency procps procps-ng
        install_epel
        install_web_dependencies 2
        in_install_update_xray_reality_web=1
        check_ssh_timeout
        in_install_update_xray_reality_web=0
        enter_temp_dir
        has_enter_temp_dir=1
        full_install_php
    else
        install_web_dependencies "${pretend_list[$selected_domain_index]}"
    fi
    # 卸载旧的伪装网站
    if [ "${pretend_list[$selected_domain_index]}" -eq 1 ]; then
        systemctl stop "cloudreve.${true_domain_list[$selected_domain_index]}" 2> /dev/null
        systemctl disable "cloudreve.${true_domain_list[$selected_domain_index]}" 2> /dev/null
    fi
    rm -rf "${nginx_prefix}/html/${true_domain_list[$selected_domain_index]}"
    systemctl daemon-reload

    pretend_list[selected_domain_index]="$pretend"
    pretend_redirect_list[selected_domain_index]="$pretend_redirect"
    pretend_redirect_index_list[selected_domain_index]="$pretend_redirect_index"
    config_nginx
    config_xray
    systemctl restart nginx xray
    sleep 2s
    if ! check_need_php; then
        systemctl stop php-fpm
        systemctl disable php-fpm
    fi
    [ $has_enter_temp_dir -eq 0 ] && enter_temp_dir
    init_web $selected_domain_index
    cd /
    rm -rf "$temp_dir"
    green "伪装网站修改完成！"
    print_config_info
}
change_protocol()
{
    config_check
    local protocol_1_old="$protocol_1"
    local protocol_2_old="$protocol_2"
    local protocol_3_old="$protocol_3"
    readProtocolConfig
    if [ "$protocol_1_old" -eq "$protocol_1" ] && [ "$protocol_2_old" -eq "$protocol_2" ] && [ "$protocol_3_old" -eq "$protocol_3" ]; then
        red "传输协议未更换"
        return 1
    fi
    config_xray
    config_nginx
    systemctl -q is-active xray && systemctl restart xray
    systemctl -q is-active nginx && systemctl restart nginx
    green "更换成功！！"
    print_config_info
}
change_uid()
{
    config_check
    local flag=""
    tyblue "-------------请输入你要修改的id-------------"
    tyblue " 1. TCP的id"
    tyblue " 2. gRPC的id"
    tyblue " 3. WebSocket的id"
    echo
    while [[ ! "$flag" =~ ^([1-9][0-9]*)$ ]] || ((flag>3))
    do
        read -rp "您的选择是：" flag
    done
    local temp_protocol="protocol_$flag"
    if [ "${!temp_protocol}" -eq 0 ]; then
        yellow "没有使用该协议！"
        exit 0
    fi
    local xid="xid_$flag"
    tyblue "您现在的id是：${!xid}"
    ! ask_if "是否要继续?(y/n)" && exit 0
    while :
    do
        xid=""
        while [ -z "$xid" ]
        do
            tyblue "-------------请输入新的id-------------"
            read -r xid
        done
        tyblue "您输入的id是：$xid"
        ask_if "是否确定?(y/n)" && break
    done
    if [ $flag -eq 1 ]; then
        xid_1="$xid"
    elif [ $flag -eq 2 ]; then
        xid_2="$xid"
    else
        xid_3="$xid"
    fi
    config_xray
    systemctl -q is-active xray && systemctl restart xray
    green "更换成功！！"
    print_config_info
}
change_grpc_serviceName()
{
    config_check
    if [ $protocol_2 -eq 0 ]; then
        yellow "没有使用gRPC协议！"
        exit 0
    fi
    tyblue "您现在的serviceName是：$serviceName"
    ! ask_if "是否要继续?(y/n)" && return 0
    while :
    do
        serviceName=""
        while [ -z "$serviceName" ]
        do
            tyblue "---------------请输入新的serviceName(字母数字组合)---------------"
            read -r serviceName
        done
        tyblue "您输入的serviceName是：$serviceName"
        ask_if "是否确定?(y/n)" && break
    done
    config_xray
    config_nginx
    systemctl -q is-active xray && systemctl restart xray
    systemctl -q is-active nginx && systemctl restart nginx
    green "更换完成！"
    print_config_info
}
change_ws_path()
{
    config_check
    if [ $protocol_3 -eq 0 ]; then
        yellow "没有使用WebSocket协议！"
        return 0
    fi
    tyblue "您现在的path是：$path"
    ! ask_if "是否要继续?(y/n)" && return 0
    while :
    do
        path=""
        while [ -z "$path" ]
        do
            tyblue "---------------请输入新的path(/+字母数字组合)---------------"
            read -r path
        done
        tyblue "您输入的path是：$path"
        ask_if "是否确定?(y/n)" && break
    done
    config_xray
    config_nginx
    systemctl -q is-active xray && systemctl restart xray
    systemctl -q is-active nginx && systemctl restart nginx
    green "更换完成！"
    print_config_info
}
reset_reality_key()
{
    config_check
    tyblue "将重新生成REALITY密钥对，这将修改客户端REALITY协议的publicKey"
    ! ask_if "是否继续？(y/n)" && exit 0
    gen_reality_key
    config_xray
    systemctl -q is-active xray && systemctl restart xray
    green "更换完成！"
    print_config_info
}
simplify_system()
{
    if systemctl -q is-active xray || systemctl -q is-active nginx || systemctl -q is-active php-fpm; then
        yellow "请先停止 Xray-REALITY+Web ！"
        exit 0
    fi
    yellow "警告："
    tyblue " 1. 此功不保证支持所有系统 (特别是某些VPS定制系统)，如果运行失败，可能导致VPS无法开机"
    tyblue " 2. 如果VPS上部署了除 Xray-REALITY+Web 之外的服务，可能被误删"
    ! ask_if "是否要继续?(y/n)" && exit 0
    echo
    local save_ssh=""
    yellow "提示：精简系统可能导致ssh配置文件(/etc/ssh/sshd_config)恢复默认"
    tyblue "这可能导致ssh端口恢复默认(22)，且有些系统默认仅允许密钥登录(不允许密码登录)"
    tyblue "您可以自行备份ssh文件，或使用脚本自动备份"
    ask_if "是否备份ssh配置文件?(y/n)" && save_ssh="$(cat /etc/ssh/sshd_config)"
    uninstall_firewall
    local i
    local ret=0
    if [ "$distro_like" == "rhel" ]; then
        local temp_backup=()
        local temp_important=('openssh-server' 'initscripts' 'tar')
        for i in "${temp_important[@]}"
        do
            rpm -q "$i" > /dev/null 2>&1 && temp_backup+=("$i")
        done
        local temp_remove_list=('perl*' 'libselinux-utils' 'zip' 'unzip' 'bzip2' 'wget' 'iproute' 'udisk*' 'libudisk*' 'gdisk*' 'libblock*' '*-devel' 'nginx*' 'rsyslog*' 'libfastjson' 'libestr' 'python3-libselinux' 'lvm2-libs' 'libaio' 'pigz' 'cpio' 'flashrom' 'fwupd' 'libgusb' 'man-db' 'selinux-*')
        #xz openssl procps-ng dbus-glib
        #libxmlb
        ! remove_dependencies "${temp_remove_list[@]}" && ret=1
        ! dnf -y autoremove && ret=1
        dnf clean all
        for i in "${temp_backup[@]}"
        do
            check_install_dependency "" "$i"
        done
    else
        local debian_remove_packages=('^cron$' '^anacron$' '^cups' '^foomatic' '^openssl$' '^snapd$' '^kdump-tools$' '^flex$' '^make$' '^automake$' '^cloud-init' '^pkg-config$' '^gcc-[1-9][0-9]*$' '^cpp-[1-9][0-9]*$' '^curl$' '^python' '^libpython' '^dbus$' '^at$' '^open-iscsi$' '^rsyslog$' '^acpid$' '^libnetplan0$' '^glib-networking-common$' '^bcache-tools$' '^bind([0-9]|-|$)' '^lshw$' '^thermald' '^libdbus' '^libevdev' '^libupower' '^readline-common$' '^libreadline' '^xz-utils$' '^selinux-utils$' '^wget$' '^zip$' '^unzip$' '^bzip2$' '^finalrd$' '^cryptsetup' '^libplymouth' '^lib.*-dev$' '^perl$' '^perl-modules' '^x11' '^libx11' '^qemu' '^xdg-' '^libglib' '^libicu' '^libxml' '^liburing' '^libisc' '^libdns' '^isc-' '^net-tools$' '^xxd$' '^xkb-data$' '^lsof$' '^task' '^usb' '^libusb' '^doc' '^libwrap' '^libtext' '^libmagic' '^libpci' '^liblocale' '^keyboard' '^libuni[^s]' '^libpipe' '^man-db$' '^manpages' '^liblock' '^liblog' '^libxapian' '^libpsl' '^libpap' '^libgs[0-9]' '^libpaper' '^postfix' '^nginx' '^libnginx' '^libpop' '^libslang' '^apt-utils$' '^google')
        #'^libp11' '^libtasn' '^libkey' '^libnet'
        local debian_keep_packages=('apt-utils' 'whiptail' 'initramfs-tools' 'isc-dhcp-client' 'netplan.io' 'openssh-server' 'network-manager' 'ifupdown' 'ifupdown-ng' 'ca-certificates')
        local keep_packages=()
        for i in "${debian_keep_packages[@]}"
        do
            english_run dpkg -s "$i" 2>/dev/null | grep -qi 'status[ '$'\t]*:[ '$'\t]*install[ '$'\t]*ok[ '$'\t]*installed[ '$'\t]*$' && keep_packages+=("$i")
        done
        keep_packages+=($(english_run dpkg --list 'grub*' | grep '^[ '$'\t]*ii[ '$'\t]' | awk '{print $2}'))
        if ! remove_dependencies "${debian_remove_packages[@]}"; then
            apt -y -f --no-install-recommends --allow-change-held-packages -o Dpkg::Options::="--force-confnew" install
            ret=1
        fi
        ! apt -y --purge --allow-change-held-packages autoremove && ret=1
        apt clean
        apt autoclean
        cp /etc/apt/sources.list /etc/apt/sources.list.bak
        sed -i 's#https://#http://#g' /etc/apt/sources.list
        for i in "${keep_packages[@]}"
        do
            check_install_dependency "$i" ""
        done
        mv /etc/apt/sources.list.bak /etc/apt/sources.list
    fi
    if [ -n "$save_ssh" ]; then
        echo "$save_ssh" > /etc/ssh/sshd_config
        if systemctl cat ssh > /dev/null 2>&1; then
            systemctl restart ssh
        else
            systemctl restart sshd
        fi
    fi
    if [ $nginx_is_installed -eq 1 ] || [ $php_is_installed -eq 1 ]; then
        install_epel
        install_remi
    fi
    [ $nginx_is_installed -eq 1 ] && install_nginx_dependencies
    [ $php_is_installed -eq 1 ] && install_php_dependencies
    [ $is_installed -eq 1 ] && install_acme_dependencies
    if [ $ret -eq 0 ]; then
        green "精简完成，建议重启系统并检查是否存在异常"
        [ -n "$save_ssh" ] && ask_if "是否现在重启系统？(y/n)" && reboot
        exit 0
    fi
    red "精简系统时有错误发生（某些软件包卸载失败）"
    if [ "$distro_like" == "rhel" ]; then
        report_bug
        exit 1
    fi
    tyblue "如果您是小白，如果发现系统有异常，建议重装系统"
    echo
    tyblue "否则，可以按照以下步骤尝试修复："
    tyblue " 1. 阅读错误信息，找到导致卸载错误的软件包 (此软件包可能由服务器提供商定制并篡改，并设置为不可修改软件包(apt hold))"
    tyblue " 2. 手动强制升级该软件包：使用 'apt update; apt --no-install-recommends reinstall 软件包名'"
    tyblue " 3. 若上一步仍然无法安装，使用 'apt policy 软件包名' 查询该软件包的官方源版本，并安装，使用命令 'apt --no-install-recommends install 软件包名=官方版本号'"
    tyblue " 4. 再次尝试运行脚本精简系统功能"
    exit 1
}

start_menu()
{
    tyblue "------------------------ Xray-REALITY+Web 搭建/管理脚本 ------------------------"
    tyblue "           系统发行版 ：           ${distro}"
    tyblue "           系统版本   ：           ${system_version}"
    tyblue "       官网：https://github.com/kirin10000/Xray-script"
    tyblue "----------------------------------- 注意事项 -----------------------------------"
    yellow " 1. 此脚本至少需要一个解析到本服务器的域名"
    tyblue " 2. 此脚本安装时间较长，建议在安装前阅读："
    tyblue "      https://github.com/kirin10000/Xray-script#安装时长说明"
    green  " 3. 建议在纯净的系统上使用此脚本 (VPS控制台-重置系统)"
    tyblue "----------------------------------------------------------------------------"
    echo
    tyblue " -----------安装/更新/卸载-----------"
    if [ $is_installed -eq 0 ]; then
        green  "   1. 安装Xray-REALITY+Web"
    else
        green  "   1. 重新安装Xray-REALITY+Web"
    fi
    purple "         流程：[更新系统组件]->[安装bbr]->[安装php]->安装Nginx->安装Xray->申请证书->配置文件->安装伪装网站"
    green  "   2. 更新Xray-REALITY+Web"
    purple "         流程：[更新脚本]->[更新系统组件]->[更新bbr]->[更新php]->[更新Nginx]->更新Xray->更新证书->更新配置文件->[更新伪装网站]"
    tyblue "   3. 更新脚本"
    tyblue "   4. 更新系统组件"
    tyblue "   5. 安装/更新bbr"
    tyblue "   6. 安装/更新php"
    tyblue "   7. 更新Nginx"
    tyblue "   8. 更新Cloudreve"
    tyblue "   9. 更新Xray"
    red    "  10. 卸载Xray-REALITY+Web"
    red    "  11. 卸载php"
    echo
    tyblue " --------------启动/停止-------------"
    tyblue "  12. 查看运行状态"
    tyblue "  13. 启用并运行Xray-REALITY+Web服务"
    purple "         启动/重启Xray, Nginx, PHP, Cloudreve；启用开机自启"
    tyblue "  14. 停止并禁用Xray-REALITY+Web服务"
    purple "         停止Xray, Nginx, PHP, Cloudreve；禁止开机自启"
    echo
    tyblue " ----------------管理----------------"
    tyblue "  15. 查看配置信息"
    tyblue "  16. 重置域名"
    purple "         将删除所有域名配置，安装过程中域名输错了造成Xray无法启动可以用此选项修复"
    tyblue "  17. 添加域名"
    tyblue "  18. 删除域名"
    tyblue "  19. 修改伪装网站类型"
    tyblue "  20. 修改传输协议"
    tyblue "  21. 修改VLESS/VMess协议id(用户ID/UUID)"
    tyblue "  22. 重新生成密钥对(修改REALITY协议publicKey)"
    tyblue "  23. 修改gRPC协议serviceName"
    tyblue "  24. 修改WebSocket协议path(路径)"
    echo
    tyblue " ----------------其它----------------"
    tyblue "  25. 精简系统"
    purple "         删除不必要的系统组件，即使已经安装 Xray-REALITY+Web 仍然可以使用此功能"
    yellow "  0. 退出脚本"
    echo
    echo
    local choice=""
    while [[ ! "$choice" =~ ^(0|[1-9][0-9]*)$ ]] || ((choice>25))
    do
        read -rp "您的选择是：" choice
    done
    case "$choice" in
        1)
            install_update_xray_reality_web
            ;;
        2)
            config_check
            update=1
            install_update_xray_reality_web
            ;;
        3)
            check_install_dependency curl curl
            check_install_dependency ca-certificates ca-certificates
            update_script
            ;;
        4)
            doupdate
            ;;
        5)
            check_install_dependency curl curl
            check_install_dependency ca-certificates ca-certificates
            enter_temp_dir
            install_bbr
            cd /
            rm -rf "${temp_dir}"
            ;;
        6)
            install_update_php
            ;;
        7)
            update_nginx
            ;;
        8)
            config_check
            ! ask_if "将对所有伪装网站的Cloudreve进行更新，是否继续？(y/n)" && exit 0
            check_install_dependency curl curl
            check_install_dependency ca-certificates ca-certificates
            enter_temp_dir
            update_cloudreves
            cd /
            rm -rf "${temp_dir}"
            ;;
        9)
            if [ $is_installed -eq 0 ]; then
                yellow "请先安装 Xray-REALITY+Web 。"
                exit 0
            fi
            check_install_dependency curl curl
            check_install_dependency ca-certificates ca-certificates
            install_update_xray
            green "Xray 更新完成！"
            ;;
        10)
            ! ask_if "确定卸载Xray-REALITY+Web？(y/n)" && exit 0
            check_install_dependency curl curl
            check_install_dependency ca-certificates ca-certificates
            remove_xray
            remove_nginx_webs
            remove_php
            "$HOME/.acme.sh/acme.sh" --uninstall
            rm -rf "$HOME/.acme.sh"
            green "卸载完成！"
            ;;
        11)
            if check_need_php; then
                yellow "有域名的伪装网站正在使用PHP，不可卸载！"
                exit 1
            fi
            ! ask_if "确定卸载PHP？(y/n)" && exit 0
            remove_php
            green "卸载完成！"
            ;;
        12)
            show_running_status
            ;;
        13)
            restart_xray_reality_web
            ;;
        14)
            disable_xray_reality_web
            ;;
        15)
            config_check
            print_config_info
            ;;
        16)
            reinit_domain
            ;;
        17)
            add_domain
            ;;
        18)
            delete_domain
            ;;
        19)
            change_pretend
            ;;
        20)
            change_protocol
            ;;
        21)
            change_uid
            ;;
        22)
            change_grpc_serviceName
            ;;
        23)
            change_ws_path
            ;;
        24)
            reset_reality_key
            ;;
        25)
            simplify_system
            ;;
        0)
            ;;
    esac
}

# 获取系统信息（系统类型、版本、包管理器、处理器指令集、处理器数量）
# 检查系统是否支持安装
check_and_get_system_info
# 防止包管理器在安装过程中被意外卸载
if [ "$pkg" == apt ]; then
    if ! output="$(english_run apt-mark manual apt)" || ! grep -qi 'set[ '$'\t]*to[ '$'\t]*manually[ '$'\t]*installed' <<< "$output"; then
        red "标记 apt 手动安装失败！"
        report_bug
    fi
    unset output
else
    if ! dnf mark install dnf >/dev/null; then
        red "标记 dnf 手动安装失败！"
        report_bug
    fi
fi

# 获取安装信息
get_install_info

start_menu
