# Xray-REALITY+Web搭建/管理脚本
## 脚本使用说明
### 1. 准备域名 && 服务器
使用此安装脚本至少需要准备一个域名，建议将域名的NS服务器托管至Cloudflare进行解析。

准备一台带公网IP的VPS服务器，支持Debian基系统(Ubuntu、Debian、Deepin等)，以及Red Hat基系统(Red Hat、CentOS、Fedora、Oracle OS)，尽量使用纯净系统，尽量使用新版本系统。
### 2. 安装curl && ca-certificates
Debian基系统(Ubuntu、Debian、Deepin等)：
```bash
apt --no-install-recommends -y install curl ca-certificates || { apt update && apt --no-install-recommends -y install curl ca-certificates; }
```
Red Hat基系统(Red Hat、CentOS、Fedora、Oracle OS等)：
```bash
dnf --setopt install_weak_deps=0 -y install curl ca-certificates || yum --setopt=install_weak_deps=0 -y install curl ca-certificates
```
### 3. 获取/更新脚本
```bash
curl -Lo Xray-REALITY+Web.sh https://github.com/bluejerry2021/Xray-script/raw/main/Xray-REALITY+Web.sh
```
### 4. 执行脚本
```bash
bash Xray-REALITY+Web.sh
```
### 5. 根据脚本提示完成安装
## 安装位置
**Nginx：**`/usr/local/nginx`

**php：**`/usr/local/php`

**Xray：** 见 **[Xray-install](https://github.com/XTLS/Xray-install)**
## 依赖列表
脚本可能自动安装以下依赖：
|用途|Debian基系统|Red Hat基系统|
|-|-|-|
|yumdb set(标记包手动安装)||yum-utils|
|dnf config-manager||dnf-plugins-core|
|setenforce/getenforce(关闭SELinux)|selinux-utils|libselinux-utils|
|ss(检查端口占用)|iproute2|iproute|
|wget|wget|wget|
|curl|curl|curl|
|wget/curl https|ca-certificates|ca-certificates|
|kill/pkill/ps/sysctl/free|procps|procps-ng|
|epel源||epel-release|
|epel源||epel-next-release|
|remi源||remi-release|
|do-release-upgrade(升级系统)|ubuntu-release-upgrader-core||
|unzip|unzip|unzip|
|curl|curl|curl|
|安装bbr内核|linux-base||
|**编译基础：**|||
|下载源码文件|wget|wget|
|解压tar源码文件|tar|tar|
|解压tar.gz源码文件|gzip|gzip|
|解压tar.xz源码文件|xz-utils|xz|
|gcc|gcc|gcc|
|g++|g++|gcc-c++|
|make|make|make|
|**acme.sh依赖：**|||
||curl|curl|
||openssl|openssl|
||cron|crontabs|
|**编译openssl：**|||
||perl-base(包含于libperl-dev)|perl-IPC-Cmd|
||perl-modules-5.32(包含于libperl-dev)|perl-Getopt-Long|
||libperl5.32(包含于libperl-dev)|perl-Data-Dumper|
|||perl-FindBin|
|**编译Nginx：**|||
||libpcre2-dev|pcre2-devel|
||zlib1g-dev|zlib-devel|
|--with-http_xslt_module|libxml2-dev|libxml2-devel|
|--with-http_xslt_module|libxslt1-dev|libxslt-devel|
|--with-http_image_filter_module|libgd-dev|gd-devel|
|--with-google_perftools_module|libgoogle-perftools-dev|gperftools-devel|
|--with-http_geoip_module|libgeoip-dev|geoip-devel|
|--with-http_perl_module||perl-ExtUtils-Embed|
||libperl-dev|perl-devel|
|**编译php：**|||
||pkg-config|pkgconf-pkg-config|
||libxml2-dev|libxml2-devel|
||libsqlite3-dev|sqlite-devel|
|--with-fpm-systemd|libsystemd-dev|systemd-devel|
|--with-fpm-acl|libacl1-dev|libacl-devel|
|--with-fpm-apparmor|libapparmor-dev||
|--with-openssl|libssl-dev|openssl-devel|
|--with-kerberos|libkrb5-dev|krb5-devel|
|--with-external-pcre|libpcre2-dev|pcre2-devel|
|--with-zlib|zlib1g-dev|zlib-devel|
|--with-bz2|libbz2-dev|bzip2-devel|
|--with-curl|libcurl4-openssl-dev|libcurl-devel|
|--with-qdbm|libqdbm-dev||
|--with-gdbm||gdbm-devel|
|--with-db4|libdb-dev|libdb-devel|
|--with-tcadb|libtokyocabinet-dev|tokyocabinet-devel|
|--with-lmdb|liblmdb-dev|lmdb-devel|
|--with-enchant|libenchant-2-dev/libenchant-dev|enchant-devel|
|--with-ffi|libffi-dev|libffi-devel|
|--enable-gd|libpng-dev|libpng-devel|
|--with-external-gd|libgd-dev|gd-devel|
|--with-webp|libwebp-dev|libwebp-devel|
|--with-jpeg|libjpeg-dev|libjpeg-turbo-devel|
|--with-xpm|libxpm-dev|libXpm-devel|
|--with-freetype|libfreetype6-dev|freetype-devel|
|--with-gmp|libgmp-dev|gmp-devel|
|--with-imap|libc-client2007e-dev|uw-imap-devel|
|--enable-intl|libicu-dev|libicu-devel|
|--with-ldap|libldap2-dev|openldap-devel|
|--with-ldap-sasl|libsasl2-dev|openldap-devel|
|--enable-mbstring|libonig-dev|oniguruma-devel|
|--with-unixODBC,--with-pdo-odbc|unixodbc-dev|unixODBC-devel|
|--with-pdo-dblib|freetds-dev|freetds-devel|
|--with-pdo-pgsql,--with-pgsql|libpq-dev|libpq-devel|
|--with-pspell|libpspell-dev|aspell-devel|
|--with-libedit|libedit-dev|libedit-devel|
|--with-mm|libmm-dev||
|--with-snmp|libsnmp-dev|net-snmp-devel|
|--with-sodium|libsodium-dev|libsodium-devel|
|--with-password-argon2|libargon2-dev|libargon2-devel|
|--with-tidy|libtidy-dev|libtidy-devel|
|--with-xsl|libxslt1-dev|libxslt-devel|
|--with-zip|libzip-dev|libzip-devel|
|编译php-imagick：|||
||autoconf|autoconf|
||git|git|
||libmagickwand-dev|ImageMagick-devel|
## 注
1.本文链接(官网)：https://github.com/kirin10000/Xray-script

2.参考教程：https://www.v2fly.org/config/overview.html https://guide.v2fly.org/ https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html https://docs.cloudreve.org/

3.域名证书申请：https://github.com/acmesh-official/acme.sh

## 声明
1. 此脚本仅供交流学习使用，请勿使用此脚本行违法之事。网络非法外之地，行非法之事，必将接受法律制裁！

2. 此脚本不是XTLS官方脚本，XTLS官方脚本 -> https://github.com/XTLS/Xray-install
