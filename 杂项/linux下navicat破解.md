# linux下navicat破解

>linux下的数据库管理软件我一直使用着datagrip将就着,可这玩意太耗费内存了,开一个相当于多开一个idea实例,而且用起来也不舒服.查阅了一些资料,总结了在linux的安装方法.

## 所需工具navicat-keygen

原始工具在此,此项目介绍了破解的原理,暂时支持到15版本.

[JohnHubcr/navicat-keygen](https://github.com/JohnHubcr/navicat-keygen)

中文使用方式在此

[lzscxb/navicat-keygen](https://github.com/lzscxb/navicat-keygen)

```shell
mkdir ~/navicat
cd ~/navicat
git clone https://github.com/lzscxb/navicat-keygen.git

cd navicat-keygen
```

使用此工具之前需要安装相关依赖

```shell
#  capstone keystone  rapidjson openssl

sudo pacman -S capstone keystone  rapidjson openssl
# 若有的项安装失败
yay -S capstone keystone  rapidjson openssl
```

## 找到15或以下版本的navicat
如果使用的是navicat的appimage还需要重新解包后再打包.

1. 对于archlinux,较为简单.

```shell
yay -S navicat15-premium-cs

yay -Ql navicat15-premium-cs
## 查看安装的目录
## 输出 /opt/navicat15-premium-cs/ 

```
可知安装到了 /opt/navicat15-premium-cs/ 目录下.

2. 对于其他没有用户打包的发行版

[百度网盘](https://pan.baidu.com/share/init?surl=2U6UaPVypjlVGpIoZqJzvA)  密码: rt1t

下载此15版本完毕后

接着下载appimage打包工具 

```shell
# 下载
cd ~/navicat
wget 'https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage'
# 授权
sudo chmod a+x appimagetool-x86_64.AppImage
```

解压包操作,得到原始的navicat15文件

```shell
# 将navicat15-premium-cs.AppImage 移动到 /home/目录下,进入AppImage目录下，打开终端并执行

mkdir navicat15-premium-cs

sudo mount -o loop navicat15-premium-cs.AppImage navicat15-premium-cs

sudo cp -r navicat15-premium-cs navicat15

sudo umount navicat15-premium-cs

rm -rf navicat15-premium-cs
```

上述准备工作做好之后进行下一步工作.
## 使用navicat-keygen破解
经过上述操作好,已经知道了原始的navicat原始文件的目录

1. navicat-patcher 替换官方公钥

```shell
# 进入navicat-keygen/bin/目录
cd ~/navicat/navicat-keygen/bin/
# 执行
sudo ./navicat-patcher ~/navicat/navicat15 # 或者/opt/navicat15-premium-cs/  请替换成自己的navicat15原始文件目录.
```

2. 对于appimage需要重新打包.

```shell
cd ~/navicat/

./appimagetool-x86_64.AppImage navicat15 navicat15.AppImage
```

3. 运行navicat软件

同时新开一个窗口,运行破解工具

```shell
cd ~/navicat/navicat-keygen/bin/

./navicat-keygen --text ./RegPrivateKey.pem
```

[![image.png](https://img2020.cnblogs.com/blog/1957451/202108/1957451-20210807110107591-120489069.png)

记得要断网运行

输入密钥到navicat后点击手动激活,
[![image.png](https://i0.hdslb.com/bfs/article/b8b494725f011058f60417a2601b7497a1b31e64.png@942w_204h_progressive.webp)

然后将navicat中的代码复制到命令窗口

[![image.png](https://i0.hdslb.com/bfs/article/f9438119f1d5e81ea361f06c68f841b73ac1b0df.png@827w_924h_progressive.webp)
双击回车键生成激活码,粘贴进navicat下面的窗口.

[![image.png](https://i0.hdslb.com/bfs/article/ad21fd6b2f52cb53226b286b2970db7df41e0f86.png@789w_935h_progressive.webp)

破解即可完成.

余下工作可以自己创建navicat的快捷方式等.现在就可以享用了.