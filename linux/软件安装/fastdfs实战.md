### fastdfs安装配置实战 ###
本次要安装的是一个track和一组storage(两台)  
1. 安装fastdfs的环境：gcc和libevent库，libfastcommon库  
V#is9?6Nqpui
   1. gcc是c编译运行环境  

         yum install gcc-c++ 

   2. libevent是第三方库  

        yum -y install libevent  

   3. libfastcommon是fast官方提供的，包含fast运行所需的基础库。  

        将libfastcommonV1.0.7.tar.gz拷贝至/usr/local/下  
        cd /usr/local   
        tar -zxvf libfastcommonV1.0.7.tar.gz   
        cd libfastcommon-1.0.7   
        ./make.sh   
        ./make.sh install   
        注意：libfastcommon安装好后会自动将库文件拷贝至/usr/lib64下，由于FastDFS程序引用usr/lib目录所以需要将/usr/lib64下的库文件拷贝至/usr/lib下。   
        要拷贝的文件如下：  
        /usr/lib64/libfastcommon.so和/usr/lib64/libfdfsclient.so。这两个文件需要拷贝到usr/lib/下，也可以创建软连接代替拷贝。

2. 安装完环境后就是安装配置track和storage

    1. 安装track  

        将FastDFS_v5.05.tar.gz拷贝至/usr/local/下  
        tar -zxvf FastDFS_v5.05.tar.gz   
        cd FastDFS   
        ./make.sh 编译   
        ./make.sh install  安装  
        track和storage是同时编译和安装的

    2. 配置track  

        进入etc/fdfs目录，拷贝一份样例文件，在样例文件的基础上修改。
        base_path=/home/yuqing/FastDFS     
        改为：   
        base_path=/home/FastDFS   
        配置http端口：   
        http.server_port=80   
        一些细则需要百度。只记录大致安装过程。  

    ```
    启动track：
    /usr/bin/fdfs_trackerd /etc/fdfs/tracker.conf restart 
    在etc/inint.d/目录下生成有一份脚本，通过脚本可以简化命令，不过etc/inint.d/脚本内容也需要将local去掉。
    ```

   3. 配置storage  

        进入etc/fdfs目录，拷贝一份样例文件，在样例文件的基础上修改。  
        修改storage.conf   
        vi storage.conf   
        group_name=group1   
        base_path=/home/yuqing/FastDFS改为：base_path=/home/ fastdfs    
        store_path0=/home/yuqing/FastDFS   
        改为：store_path0=/home/fastdfs/fdfs_storage   
        #如果有多个挂载磁盘则定义多个store_path，如下   
        #store_path1=.....   
        #store_path2=......   
        tracker_server=192.168.101.3:22122   #配置 tracker服务:IP   
        #如果有多个则配置多个tracker   
        tracker_server=192.168.101.4:22122   
        #配置http端口   
        http.server_port=80   

        本次搭建tracker有一个，storage有俩（一组）  
        如果一个组内有多个storage则会上传两份文件到每一台服务器中

        ```
        启动： 
        /usr/bin/fdfs_storaged /etc/fdfs/storage.conf restart 
        在etc/inint.d/目录下生成有一份脚本，通过脚本可以简化命令，不过etc/inint.d/脚本内容也需要将local去掉。  
        ```
3. fastdfs和nginx整合，提高访问速度。

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
--http-scgi-temp-path=/var/temp/nginx/scgi 
--add-module=/usr/local/fastdfs-nginx-module/src

以下为官方方法  
Copy right 2010 Happy Fish / YuQing

This software may be copied only under the terms of the GNU General
Public License V3, Please visit the FastDFS Home Page for more detail.
English language: http://english.csource.org/
Chinese language: http://www.csource.org/

#step 1. first install the FastDFS storage server and client library,
         the FastDFS version should >= 2.09. download address:
         https://code.google.com/p/fastdfs/downloads/list

#step 2. install nginx server
         FastDFS nginx module test passed with nginx 0.8.53,
         my nginx installed in /usr/local/nginx

#step 3. download FastDFS nginx module source package and unpack it, such as:
tar xzf fastdfs_nginx_module_v1.16.tar.gz

#step 4. enter the nginx source dir, compile and install the module, such as:
cd nginx-1.5.12
./configure --add-module=/home/yuqing/fastdfs-nginx-module/src
make; make install

Notice: before compile, you can change FDFS_OUTPUT_CHUNK_SIZE and 
        FDFS_MOD_CONF_FILENAME macro in the config file as:
CFLAGS="$CFLAGS -D_FILE_OFFSET_BITS=64 -DFDFS_OUTPUT_CHUNK_SIZE='256*1024' -DFDFS_MOD_CONF_FILENAME='\"/etc/fdfs/mod_fastdfs.conf\"'" 

#step 5. config the nginx config file such as nginx.conf, add the following lines:

        location /M00 {
            root /home/yuqing/fastdfs/data;
            ngx_fastdfs_module;
        }

#step 6. make a symbol link ${fastdfs_base_path}/data/M00 to ${fastdfs_base_path}/data,
         command line such as:
ln -s /home/yuqing/fastdfs/data  /home/yuqing/fastdfs/data/M00

#step 7. change the config file /etc/fdfs/mod_fastdfs.conf, more detail please see it

#step 8. restart the nginx server, such as:
/usr/local/nginx/sbin/nginx -s stop; /usr/local/nginx/sbin/nginx

但以上文件并不完全适用  在编译之前应该做以下事情。  
主要是因为我们刚才安装库的时候安装在了use下而不是usr/local下
FastDFS-nginx-module 
将 FastDFS-nginx-module_v1.16.tar.gz 传至 fastDFS 的 storage 服务器的  
/usr/local/下，执行如下命令：   
cd /usr/local   
tar -zxvf FastDFS-nginx-module_v1.16.tar.gz   
cd FastDFS-nginx-module/src   
修改config文件将/usr/local/路径改为/usr/   

//常用命令如下
启动tracker  
/usr/bin/fdfs_trackerd /etc/fdfs/tracker.conf restart   
启动storage  
/usr/bin/fdfs_storaged /etc/fdfs/storage.conf restart     
上传命令  
/usr/bin/fdfs_test /etc/fdfs/client.conf upload /root/f1.jpg 
启动nginx  
./nginx -s reload  
./nginx -s stop  
./nginx -s quit


