# fastdfs搭建
## 1 fastdfs的安装
1. 编译和安装所需的依赖包
```
yum install make cmake gcc gcc-c++ libevent 
```
2. 安装libfastcommon
```
解压
./make.sh
./make.sh install;

libfastcommon 默认安装到了/usr/lib64/libfastcommon.so
因为FastDFS主程序设置的lib目录是/usr/lib，所以需要创建软链接,或者复制.

ln -s /usr/lib64/libfastcommon.so /usr/lib/libfastcommon.so
ln -s /usr/lib64/libfdfsclient.so /usr/lib/libfdfsclient.so
```
3. 安装fastdfs
```
cd ~/devfile/fastdfs/FastDFS
./make.sh
./make.sh install
输出如下
##
mkdir -p /usr/bin
mkdir -p /etc/fdfs
cp -f fdfs_trackerd /usr/bin
if [ ! -f /etc/fdfs/tracker.conf.sample ]; then cp -f ../conf/tracker.conf /etc/fdfs/tracker.conf.sample; fi
mkdir -p /usr/bin
mkdir -p /etc/fdfs
cp -f fdfs_storaged  /usr/bin
if [ ! -f /etc/fdfs/storage.conf.sample ]; then cp -f ../conf/storage.conf /etc/fdfs/storage.conf.sample; fi
mkdir -p /usr/bin
mkdir -p /etc/fdfs
mkdir -p /usr/lib64
cp -f fdfs_monitor fdfs_test fdfs_test1 fdfs_crc32 fdfs_upload_file fdfs_download_file fdfs_delete_file fdfs_file_info fdfs_appender_test fdfs_appender_test1 fdfs_append_file fdfs_upload_appender /usr/bin
if [ 0 -eq 1 ]; then cp -f libfdfsclient.a /usr/lib64; fi
if [ 1 -eq 1 ]; then cp -f libfdfsclient.so /usr/lib64; fi
mkdir -p /usr/include/fastdfs
cp -f ../common/fdfs_define.h ../common/fdfs_global.h ../common/mime_file_parser.h ../common/fdfs_http_shared.h ../tracker/tracker_types.h ../tracker/tracker_proto.h ../tracker/fdfs_shared_func.h ../storage/trunk_mgr/trunk_shared.h tracker_client.h storage_client.h storage_client1.h client_func.h client_global.h fdfs_client.h /usr/include/fastdfs
if [ ! -f /etc/fdfs/client.conf.sample ]; then cp -f ../conf/client.conf /etc/fdfs/client.conf.sample; fi
##

服务脚本在：
/etc/init.d/fdfs_storaged
/etc/init.d/fdfs_trackerd

配置文件在（样例配置文件）:
/etc/fdfs/client.conf.sample
/etc/fdfs/storage.conf.sample
/etc/fdfs/tracker.conf.sample

命令工具在/usr/bin/目录下的：
fdfs_appender_test
fdfs_appender_test1
fdfs_append_file
fdfs_crc32
fdfs_delete_file
fdfs_download_file
fdfs_file_info
fdfs_monitor
fdfs_storaged
fdfs_test
fdfs_test1
fdfs_trackerd
fdfs_upload_appender
fdfs_upload_file
stop.sh
restart.sh


因为FastDFS服务脚本设置的bin目录是/usr/local/bin，但实际命令安装在/usr/bin，可以进入/user/bin 目录使用以下命令查看 fdfs 的相关命令：
cd /usr/bin/
ls | grep fdfs

因此需要修改FastDFS服务脚本中相应的命令路径，也就是把/etc/init.d/fdfs_storaged和/etc/init.d/fdfs_trackerd 两个脚本中的/usr/local/bin修改成/usr/bin：
vim /etc/init.d/fdfs_trackerd
手动修改或者
使用查找替换命令进统一修改：:%s+/usr/local/bin+/usr/bin
  
vim /etc/init.d/fdfs_storaged
使用查找替换命令进统一修改：:%s+/usr/local/bin+/usr/bin

至此fastdfs的trackerd storaged都已经安装好,且可以通过修改过得脚本管理服务.
```
## 2 fdfs搭建集群
fdfs的集群搭建主要是通过配置文件
接下来就是通过修改配置文件来搭建集群.
为节省资源架构如下
机器名|ip|安装软件
-|-|-
tracker01 |	192.168.1.111 |	FastDFS,libfastcommon,nginx,fastdfs-nginx-module
tracker02 |	192.168.1.112 |	FastDFS,libfastcommon,nginx,fastdfs-nginx-module
storage01 |	192.168.1.111 |	FastDFS,libfastcommon,nginx,fastdfs-nginx-module
storage02 |	192.168.1.112 |	FastDFS,libfastcommon,nginx,fastdfs-nginx-module
客户机1  |   192.168.1.111  |   Fastdfs_client
使用虚拟机搭建,搭建完一台后,复制虚拟机更改配置文件即可.
1. 配置tracker
```
cp storage.conf.sample storage.conf
cp tracker.conf.sample tracker.conf
vim /etc/fdfs/tracker.conf

disabled=false               //启用配置文件
port=22122                   //tracker 的端口号，一般采用 22122 这个默认端口
base_path=/fastdfs/tracker   //tracker 的数据文件和日志目录
 
# the method of selecting group to upload files
# 0: round robin
# 1: specify group
# 2: load balance, select the max free space group to upload file
store_lookup=0              //采取轮巡方式选择要上传的组进行存储，默认2 选择最大空闲空间的组

```
2. 配置storage
```
vim /etc/fdfs/storage.conf
#需要修改的内容如下
disabled=false                          //启用配置文件
group_name=group1                       //组名（第一组为 group1，第二组为 group2）
port=23000 # storage服务端口（默认23000,一般不修改）
base_path=/fastdfs/storage # 数据和日志文件存储根目录
store_path0=/fastdfs/storage/data # 第一个存储目录
tracker_server=192.168.1.111:22122 # tracker服务器IP和端口
tracker_server=192.168.1.112:22122 # tracker服务器IP和端口
http.server_port=80 # http访问文件的端口(默认8888,看情况修改,和nginx中保持一致)
```
3. 配置Client
```
vim /etc/fdfs/client.conf
#需要修改的内容如下
base_path=/fastdfs/client
tracker_server=192.168.1.111:22122 # tracker服务器IP和端口
tracker_server=192.168.1.112:22122 # tracker服务器IP和端口

根据以上配置,建立文件夹.
mkdir -p /fastdfs/client
mkdir -p /fastdfs/storage
mkdir -p /fastdfs/storage/data
mkdir -p /fastdfs/tracker

开放以上端口,多开放几个万一有用呢.
firewall-cmd --zone=public --add-port=22122/tcp --permanent
firewall-cmd --zone=public --add-port=23000/tcp --permanent
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=8888/tcp --permanent
firewall-cmd --zone=public --add-port=8080/tcp --permanent
```
4. 安装nginx和FastDFS-nginx-module 
安装nginx是为了使用http访问文件服务器上的文件
FastDFS-nginx-module是ngixn的插件,当访问的文件未及时同步时,可以自动请求组内的其他storage.
```
首先
cp /usr/lib64/libfdfsclient.so /usr/lib/ 
mkdir -p /var/temp/nginx/client 

tar -zxvf FastDFS-nginx-module_v1.16.tar.gz 
cd FastDFS-nginx-module/src 
vim config 
修改config文件将/usr/local/路径改为/usr/ 

fastdfs-nginx-module 的配置文件默认地址为/etc/fdfs/mod_fastdfs.conf
如果没有,可以复制一份到/etc/fdfs/ 目录下

cd nginx-1.8
执行以下,最后一行为mod源码所在位置.

./configure \
--prefix=/usr/local/nginx \
--pid-path=/var/run/nginx/nginx.pid \
--lock-path=/var/lock/nginx.lock \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--with-http_gzip_static_module \
--http-client-body-temp-path=/var/temp/nginx/client \
--http-proxy-temp-path=/var/temp/nginx/proxy \
--http-fastcgi-temp-path=/var/temp/nginx/fastcgi \
--http-uwsgi-temp-path=/var/temp/nginx/uwsgi \
--http-scgi-temp-path=/var/temp/nginx/scgi \
--add-module=/home/hcq/devfile/fastdfs/fastdfs-nginx-module/src

make 
make install

至此nginx和mod安装完成,可以通过nginx访问上传的文件.
修改nginx配置文件
vim /usr.local/nginx/conf/nginx.conf
server{
        listen      80;
        server_name 192.168.1.111;

        location /group1/M00{
                root  /fastdfs/storage/data;
                ngx_fastdfs_module;
                }
    }
```
5. 复制虚拟机搭建集群
修改storage的group为group2
```
vim /etc/fdfs/storage.conf
#需要修改的内容如下
group_name=group2                       //组名（第一组为 group1，第二组为 group2）

vim /usr/local/nginx/conf/nginx.conf
server{s
        listen      80;
        server_name 192.168.1.112;

        location /group2/M00{
                root  /fastdfs/storage/data/data;
                ngx_fastdfs_module;
                }
    }


```
6. 启动 
```
sudo /etc/init.d/fdfs_trackerd start
sudo /etc/init.d/fdfs_storaged start

所有Storage节点都启动之后，可以在任一 Storage 节点上使用如下命令查看集群信息：
/usr/bin/fdfs_monitor /etc/fdfs/storage.conf
```

7. 测试
```
在任意机器下执行
上传文件
/usr/bin/fdfs_test /etc/fdfs/client.conf upload pic/p1.jpg (此种方式不会轮训上传)
返回如下
group_name=group2, ip_addr=192.168.1.112, port=23000
storage_upload_by_filename
group_name=group2, remote_filename=M00/00/00/wKgBcF4E08iAWJ4kAAfNHkhMyWo887.jpg
source ip address: 192.168.1.112
file timestamp=2019-12-26 10:37:44
file size=511262
file crc32=1212991850
example file url: http://192.168.1.112/group2/M00/00/00/wKgBcF4E08iAWJ4kAAfNHkhMyWo887.jpg
storage_upload_slave_by_filename
group_name=group2, remote_filename=M00/00/00/wKgBcF4E08iAWJ4kAAfNHkhMyWo887_big.jpg
source ip address: 192.168.1.112
file timestamp=2019-12-26 10:37:44
file size=511262
file crc32=1212991850
example file url: http://192.168.1.112/group2/M00/00/00/wKgBcF4E08iAWJ4kAAfNHkhMyWo887_big.jpg

或者
/usr/bin/fdfs_upload_file /etc/fdfs/client.conf pic/p1.jpg (会采用轮训上传的方式)
返回如下
group2/M00/00/00/wKgBcF4E8tuAEh8XAAfNHkhMyWo607.jpg

/usr/bin/fdfs_upload_file /etc/fdfs/client.conf pic/p1.jpg
group1/M00/00/01/wKgBb14E-AaAfkntAAfNHkhMyWo582.jpg


启动nginx通过http访问
需要修改插件的配置文件
vim /etc/fdfs/mod_fastdfs.conf
base_path=/fsatdfs/treacker
tracker_server=192.168.1.111:22122 
tracker_server=192.168.1.112:22122 
url_have_group_name=true  #url中包含group名称 
store_path0=/home/fastdfs/fdfs_storage   #指定文件存储路径 

实际上因为架构的问题,这个插件是没有作用的,一个组内有多台storage才有作用.

/usr/local/nginx/sbin/nginx
遇到了一个nginx无法启动的问题,查看nginx的错误日志解决掉.
nginx启动后通过本地浏览器访问即可查看上传的图片.

```

