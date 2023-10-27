# Xray-TLS+Web搭建/管理脚本
## 目录
[1. 脚本特性](#脚本特性)

[2. 注意事项](#注意事项)

[3. 安装时长说明](#安装时长说明)

[4. 脚本使用说明](#脚本使用说明)

[5. 运行截图](#运行截图)

[6. 伪装网站说明](#伪装网站说明)

[7. 关于TLS握手、TLS指纹和ALPN](#关于tls握手tls指纹和alpn)

[8. 关于gRPC与WebSocket](#关于gRPC与WebSocket)

[9. 安装位置](#安装位置)

[10. 依赖列表](#依赖列表)

[11. 注](#注)
## 脚本特性
1. 支持 (VLESS/VMess)-(TCP/gRPC/WebSocket)-(XTLS/TLS) + Web 的搭建/管理，支持多种协议并存

2. 集成 多版本bbr/锐速 安装选项
 
3. 支持多种系统 (Ubuntu CentOS Debian deepin fedora ...) 

4. 支持多种指令集 (x86 x86_64 arm64 ...)

5. 支持ipv6only服务器 (需自行设置dns64)

6. 集成删除阿里云盾和腾讯云盾功能 (仅对阿里云和腾讯云服务器有效)

7. 使用Nginx作为网站服务

8. 使用Xray作为前置分流器

9. 使用acme.sh自动申请/更新域名证书

10. 支持选择搭建个人网盘作为伪装网页
## 注意事项
1. 此脚本需要一个解析到服务器的域名 (支持cdn)

2. 此脚本安装时间较长，见 **[安装时长说明](#安装时长说明)**

3. 此脚本设计为个人VPS用户使用，不适合机场主使用 (此脚本没有多用户管理/流量统计等功能)。

4. 建议在纯净的系统上使用此脚本 (VPS控制台-重置系统)
## 安装时长说明
此脚本的安装时间比较长 (**[安装时长参考](#安装时长参考)**) ，原因见[这里](#为什么脚本安装时间那么长)。

此脚本适合安装一次后长期使用，不适合反复重置系统安装，这会消耗您的大量时间。如果需要更换配置和域名等，在管理界面都有相应的选项。

如果有快速安装的需求，推荐在 **[Xray-core#Installation](https://github.com/XTLS/Xray-core#Installation)** 中选择其他脚本
### 安装时长参考
安装流程：

`[升级系统组件]->[安装bbr]->[安装php]->安装Nginx->安装Xray->申请证书->配置文件->[配置伪装网站]`

其中`[]`包裹的部分是可选项。

**这是一台单核1G的服务器的平均安装时长，仅供参考：**
|项目|时长|
|-|-|
|升级已安装软件|0-10分钟|
|升级系统|10-20分钟|
|安装bbr|0-3分钟|
|安装php|Centos8(gcc8.3 4.18内核):20-60分钟|
||Ubuntu20.10(gcc10.2 5.11-rc3内核):15-20分钟|
||Debian10(gcc8.3 4.19内核):10-15分钟|
|安装Nginx|13-15分钟|
|安装Xray|<半分钟|
|申请证书|1-2分钟|
|配置文件|<100毫秒|
|配置伪装网站|Nextcloud:1-3分钟|
||Cloudreve:1-2分钟|
### 为什么脚本安装时间那么长？
之所以时间相比别的脚本长，有三个原因：
```
1.集成了安装bbr的功能
2.集成更新系统及软件包的功能
3.(主要原因) 脚本的Nginx和php是采用源码编译的形式，其它脚本通常直接获取二进制程序
```
之所以采用编译的形式，主要考虑的原因为：
```
1.便于管理
2.便于适配多种系统
```
编译相比直接安装二进制文件的优点有：
```
1.运行效率高 (编译时采用了-O3优化)
2.软件版本新 (可以对比本脚本与其他脚本Nginx的版本)
```
缺点就是编译耗时长
## 脚本使用说明
### 1. 安装wget && ca-certificates
Debian基系统(包括Ubuntu、Debian、deepin)：
```bash
apt --no-install-recommends -y install wget ca-certificates || (apt update && apt --no-install-recommends -y install wget ca-certificates)
```
Red Hat基系统(包括CentOS、fedora)：
```bash
dnf -y install wget ca-certificates || yum -y install wget ca-certificates
```
### 2. 获取/更新脚本
```bash
wget -O Xray-TLS+Web-setup.sh https://github.com/kirin10000/Xray-script/raw/main/Xray-TLS+Web-setup.sh
```
### 3. 执行脚本
```bash
bash Xray-TLS+Web-setup.sh
```
### 4. 根据脚本提示完成安装
## 运行截图
<div>
    <img width="400" src="https://github.com/kirin10000/Xray-script/blob/main/image/menu.jpg">
</div>
<div>
    <img width="600" src="https://github.com/kirin10000/Xray-script/blob/main/image/protocol.jpg">
</div>

## 伪装网站说明
### 伪装网站的作用
这个网站是用你的域名搭建的一个网站，搭建完成后可以直接在浏览器上输入你的域名访问。

你使用Xray进行代理的全部流量都将伪装成访问这个网站的流量。

注意伪装网站不是万能的，据部分人的经验，只要你的月流量超过一定限度运营商就会把你封喽，不管你的伪装网站是什么。也就是说哪怕你**完全不代理，只是正常访问你的网站访问了太多的流量，也可能被封**。
### 伪装网站的选择
使用VPS自建Xray代理在流量的常见特征有 **单点性** 、 **大流量性** 、 **长时间性** 、 **GO-TLS指纹特性** 、 **出入相同性** 等。

* **单点性** 指使用的人少，一般只有自己，即使分享给朋友，一般也不会太多。
* **长时间性** 不单指时间长，也指坚持一个月或一年每天都使用代理。
* **GO-TLS指纹特性** **在不伪装浏览器指纹的前提下**，从TLS握手信息中可以判断出客户端是GO程序，详见[此处](#关于tls握手tls指纹和alpn)。
* **出入相同性** 指入VPS和出VPS的流量在时间和大小上几乎相同，比如使用Xray代理浏览`BiliBili`，从`BiliBili`到`VPS(Xray服务端)`的流量，和从`VPS`到`Xray客户端`的流量在时间上和大小上是几乎相同的。**出入相同性** 是所有代理的通病，目前还没有太好的伪装方法，但是因为VPS不在大陆，如果不是被特别关注的对象，一般不会被审查。

既然使用Xray进行代理的全部流量都将伪装成访问这个网站的流量，那么我们选择伪装网站就是要尽量选择**流量特征与Xray代理的流量特征相同的网站**。

1. **Cloudreve 和 Nextcloud**

他们都是个人网盘，个人网盘可以理解为使用自己的VPS搭建起来的百度网盘，区别就是文件都存放在VPS中，并且自己是网盘的管理员。

个人网盘与上面所说特征的吻合数最多，包括 **单点性** 、 **大流量性** 、 **GO-TLS指纹特性** 、 **长时间性** 等，建议选择。

关于**GO-TLS指纹特性**，**在不伪装浏览器指纹的前提下**，将alpn设置为http/1.1，可以伪装成GO语言实现的WebDav客户端，详见[此处](#关于tls握手tls指纹和alpn)。

Cloudreve 与 Nextcloud 的区别如下：
||优点|缺点|
|-|-|-|
|Nextcloud|功能更多更强大，用的人更多|需要安装php，安装php需要额外很多时间(见 **[安装时长参考](#安装时长参考)**)，同时也比Cloudreve占用更多系统资源，因此不建议小机使用。|
|Cloudreve|轻量化、安装快(不需要php)、占用系统资源少|功能较少，使用的人较少|
2. **403页面**

基本上所有大网站都有网站后台。比如哔哩哔哩的网址是`www.bilibili.com`。但是在播放视频时，提供视频文件的却是另外一个网址，在播放视频时右键点击`视频统计信息`，其中的`Video Host`就是。这类网址只有打开特定的url后缀才有内容，如果url不对，返回的就是一个错误页面。而403页面就是伪装成一个网站后台。

也就是说伪装成403页面，除了你自己，没人知道你的网站到底有没有东西。

3. **自定义静态网站**

可以放置自己的静态网站源代码，不建议小白选择。

4. **自定义反向代理网站**

不建议选择，因为反向代理往往只是反向代理几个html和js文件，网站里面的大部分内容依然是网站后台提供的。不符合大流量特点。
## 关于TLS握手、TLS指纹和ALPN
虽然TLS是一项加密技术，但在TLS握手的过程中会有一些明文的信息传输，其中包括SNI信息(由serverName参数指定)、ALPN、加密套件等。

目前TLS的标准中并没有对这些明文做严格的要求，所以在不同的TLS实现下这些明文信息的格式可谓五花八门，这些不同TLS实现所具有的不同的明文特征就是TLS指纹。

通过TLS指纹可以反推你所使用的TLS实现，比如Chrome的TLS，FireFox的TLS，GO语言官方库的TLS等。

Xray默认使用的是GO语言官方提供的TLS库，这也是几乎所有GO语言程序所使用的TLS库。Xray也可以模拟Chrome、FireFox、Safari的指纹，但目前只有TCP协议支持。

当使用TCP且不伪装浏览器指纹时，可以自由指定义ALPN。建议设置为http/1.1，这样可以将Xray客户端伪装成GO语言实现的WebDav客户端(如 **[gowebdav](https://github.com/studio-b12/gowebdav)**)。WebDav是网盘特有的协议，且该协议基于HTTP/1.1，详见： **[WebDav](https://en.wikipedia.org/wiki/WebDAV)** 。

若选择伪装浏览器指纹，客户端配置中的alpn参数失效，且ALPN将被固定为h2,http/1.1。同样，当使用WebSocket时，ALPN将被固定为http/1.1；当使用gRPC时，ALPN将被强制添加h2。因此，使用WebSocket还是可以伪装成GO语言WebDav客户端的，gRPC则不行。
## 关于gRPC与WebSocket
当正在使用的CDN同时支持gRPC与WebSocket时，两者之间改如何选择呢？他们的主要区别体现在以下三个方面：ALPN、延迟和性能。

关于ALPN，见[此处](#关于tls握手tls指纹和alpn)。

关于延迟，gRPC自带mux，因此延迟更低。注意这里指的是打开网站的延迟，mux并不能降低游戏延迟。

关于性能，WebSocket的性能更强，如果你的设备性能较弱的话，如家用普通路由器，用WebSocket速度会快一些。
## 安装位置
**Nginx：**`/usr/local/nginx`

**php：**`/usr/local/php`

**Cloudreve：**`/usr/local/cloudreve`

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

4.bbr脚本来自：https://github.com/teddysun/across/blob/master/bbr.sh

5.bbr2脚本来自：https://github.com/yeyingorg/bbr2.sh (Ubuntu Debian) https://github.com/jackjieYYY/bbr2 (CentOS)

6.bbrplus脚本来自：https://github.com/chiakge/Linux-NetSpeed

#### 此脚本仅供交流学习使用，请勿使用此脚本行违法之事。网络非法外之地，行非法之事，必将接受法律制裁！！
