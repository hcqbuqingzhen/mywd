# 使用nvm管理node版本
## 1. window下操作 
### 第一步：下载NVM下载nvm并解压
nvm-window 下载地址：https://github.com/coreybutler/nvm-windows/releases

下载文件，然后解压得到nvm-noinstall文件夹，重命名为nvm(名字随意)。
这里有四个可下载的文件:
nvm-noinstall.zip： 这个是绿色免安装版本，但是使用之前需要配置。（个人推荐这个）
nvm-setup.zip：这是一个安装包，下载之后点击安装，无需配置就可以使用，方便。
Source code(zip)：zip压缩的源码
Sourc code(tar.gz)：tar.gz的源码，一般用于*nix系统

### 第二步：配置NVM环境变量
1 .在nvm文件夹中创建settings.text,写入以下内容保存：

1  root: D:\dev\nvm
2  path: D:\dev\nodejs
root: 是nvm.exe所在目录

path:node快捷方式所在的路径。当使用nvm use XXXnode版本号的时候会根据path的设置创建快捷方式。每切换不同版本，这个快捷方式里的内容根据使用的node的版本而变化。

注意：手打的话root和path的冒号后面一定要有一个空格，不然安装node的时候是不会安装到该nvm文件夹里。

2. 计算机——右键——属性——高级系统设置——环境变量

新建变量名：NVM_HOME，变量值：D:\dev\nvm

新建变量名：NVM_SYMLINK，变量值：D:\dev\nodejs

找到Path选择编辑添加%NVM_HOME%;%NVM_SYMLINK%;

注意：

A.变量名必须为NVM_HOME和NVM_SYMLINK，之前重新安装突然想试试变个名会如何于是给NVM后面加个s，然后出问题了。

B.编辑PATH的时候添加%NVM_HOME%前面一定要分号结尾。

C.path中%NVM_HOME%与%NVM_SYMLINK%的顺序不要反。

3.检测nvm安装成功与否

命令台输入 nvm 跳出呼啦啦一大堆告诉你怎么操作的就是安装成功了。

### 第三步 安装node

1. nvm安装
nvm install node版本号   //安装某个版本node
nvm use node版本号       //使用某版本node
node -v                //查看版本号，需要use后才能才能使用node -v查看版本

2. 下载安装

下载个版本的nodejs放入2中的root文件夹

### 第四 关于全局安装npm包的问题

众所周知,node版本的包的版本是一个很复杂的问题.一个node版本下某个包支持的最后版本可能是不相同的,如果两个node版本共用一个全局库,容易造成包版本问题.

可以知道 nvm中path=node快捷方式所在的路径,可以设置
npm config set prefix "path\moudel"  根据不同node版本配置不同全局库.
npm config set cache "path\node_cache" 根据不同node版本配置不同缓存库.

## 2. linux
### 安装
```shell
sudo pacman -S nvm
```
完成,即可使用nvm

### 原理解析
nvm安装成功后会提示让把一句话加入到bash或zsh的bashrc 中
[![XwugOA.png](https://s1.ax1x.com/2022/06/05/XwugOA.png)](https://imgtu.com/i/XwugOA)
```shell
vim /usr/share/nvm/init-nvm.sh 
```


[![XwK37t.png](https://s1.ax1x.com/2022/06/05/XwK37t.png)](https://imgtu.com/i/XwK37t)

```shell
vim /usr/share/nvm/nvm.sh 
```

shell太长了,其实就是将node目录加入到path.

