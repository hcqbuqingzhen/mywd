---
title: archlinux+kde桌面安装
date: 2020-03-15 21:42:11
tags: linux
---

# archlinux+kde桌面安装

网上看到很多教程，也没有真正适合自己的，毕竟要自己踩一下坑才能安装好，以下为安装实录。

## 一 archlinux的安装

1 准备u盘，制作启动盘

	windows下可以使用很多工具刻录，我使用的是rufus这个小工具。
	linux可以使用命令行，请自行搜索。

2 启动到u盘 ，不同电脑不同。
	u盘的启动项带uefi字母的是uefi方式启动。	
3 验证启动模式
	输入 ls /sys/firmware/efi/efivars
	如果有目录，则证明是uefi方式启动。
4 连接到因特网
	1）检查电脑网卡
	     ip link
	2）连接到网络
	    如果电脑是通过网线连接路由器,使用以下命令即可连接。使用wifi请接着看 3）
		systemctl enable dhcpcd
		
		systemctl start dhcpcd
	3）如果使用wifi ，使用如下命令。
		wifi-menu会出现选择wifi界面。

		如果输入了密码不管用，ping不通，使用如下命令。
		wpa_passphrase wifiname password > /etc/wpa_supplicant/example.conf
			 wifiname:wifi的名   ，password：wif 密码
		wpa_supplicant -B -i interface -c /etc/wpa_supplicant/example.conf
			interface ：无线网卡名 常见为: wlan0 wlan2 。即为 ip a命令中显示的设备名。
		decpcd interface
		
		以上三步；第一步为生成一个wifi配置文件，第二步使用wpa_supplicant工具连接，使用生成的配置文件。
		第三部为自动分配ip.
	4) ping www.baidu.com 看是否连接到网络  ctrl+c 停止ping。
5  更新系统时间
	timedatectl set-ntp true
	
	timedatectl status 检查服务状态
6 更换国内软件源加快速度
	vim  /etc/pacman.d/mirrorlist
	搜索中国的源（搜索China），并将中国的源复制（剪切）到开头。我复制的是ustc中科大的源	
	此处vim用法自行搜索。		
7 给硬盘分区，格式化和挂载。	
	fdisk -l  （或者lsblk）查看本机的硬盘。记住自己要安装的位置的名字。
	
	使用cfdisk来给硬盘分区。
	如果是新的硬盘，需要 1 parted /dev/sdx  2 mktable 输入gpt 来建立分区表。
	cfdisk /dev/sdx  x表示硬盘的位置，按照提示给硬盘分区。
	如果是新的硬盘（本电脑上没有安装其他的操作系统）需要建立efi分区，
	我只建立了一个 /分区 和一个swap分区 。 可按自己的需要建立分区。
	lsblk查看建立的分区

	格式化
	1 格式化 efi分区   mkfs.vfat  /dev/sdxn 。如果本电脑上已经有其他操作系统，表示已经有efi
	分区，这一步不用格式化，（无视这一条）到建立引导的时候会挂载已经有的efi分区。
	2 格式化其他分区，除了swap分区都格式化为ext4.
	mkfs.ext4  /dev/sdxn 。
	mkswap  -f  /dev/sdxn 。

	挂载
	mount /dev/sdc1 /mnt  挂载分区1到跟目录

8 安装 使用pacman从网络下载包，并安装到跟目录
	pacstrap /mnt base base-devel  linux linux-firmware  vi vim nano dhcpcd  netctl  
	
	base   linux   linux-firmware  是官方文档上写的，其他为自己选的。201911版本 vi vim nano dhcpcd  netctl
	这几个包我在安装前查阅资料，可能已经在base包中去除，需要手动安装。
	
9 生成fstab文件
	genfstab -U /mnt  >> /mnt/etc/fstab 
	这一步是生成本机的文件系统文件，以便在linux启动的时候读取。

10 切换到新安装的系统下 
	arch-chroot /mnt

11 设置 时区
	上海
	 ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	设置硬件时间
	hwclock --systohc
12 本地化
	1）vim  /etc/locale.gen
	查找 en_US.UTF-8 UTF-8 并将注释去掉
	2） locale-gen
	3）创建 locale.conf 并编辑
	vim /etc/locale.conf  
	添加内容 
	LANG=en_US.UTF-8  保存退出
	
12 设置 Root 密码
	passwd root
13 常用包
	pacman -S iw wpa_supplicant dialog
14 安装微码 
	pacman -S intel-ucode 英特尔选
	pacman -S amd-ucode
15 安装引导程序
	pacman -S grub efibootmgr

16 建立引导
	如果电脑上安装了其他系统如windows,原本就存在efi分区了。
	
	mkdir /boot/EFI
	mount /dev/sdxn   /boot/EFI

	将已有的EFIF分区挂载到 /boot/EFI 下
	
	设置引导 
	 grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=GRUB
	（如果是全新安装，本台电脑没有其他引导，直接执行设置引导命令即可。）
	成功安装后
	

	设置配置文件
	grub-mkconfig -o /boot/grub/grub.cfg
	
	reboot 重启 
	安装完成重启后（需要自己到主板修改引导顺序），grub的引导可能没有window引导项供选择，此处进入arch后自行网上搜索
	如何添加window引导。
	我本身用的一个安装黑苹果的clover引导用来引导win和linux ，这个界面做的比较好看。（去黑苹果论坛找个clover文件放到efi分区下，主板设置一下即可）

以下为进入到新系统并且联网后
## 二 安装kde桌面 
	
	1 安装xxorg 服务  （桌面依赖这个服务）
		pacman -S xorg
	2 安装触摸板驱动 
		pacman -S xf86-input-synaptics  (笔记本可选 )
	3 安装中文字体
		pacman -S ttf-dejavu wqy-microhei wqy-zenhe
	4 安装声卡相关 
		 pacman -S alsa-utils pulseaudio pulseaudio-alsa
	5 安装网络工具（多个发行版都依赖这个包管理网络）
		安装：pacman -S networkmanager net-tools 
		启动：systemctl enable NetworkManager
		          systemctl enable dhcpcd
	6 桌面及kde软件 
		pacman -S plasma kde-applications
	7 创建普通用户 并给用户提权
		useradd -m -G wheel -s /bin/bash  xiaobai            #( 注释  xiaobai ：username)
		passwd xiaobai  给小白设置密码 
		visudo 此命令会打开一个文件 搜索wheel 将有三个 "all" 的那一行注释放开 。保存。
	8 安装sddm （登陆桌面）
		安装：
		pacman -S sddm sddm-kcm
		启动：
		systemctl enable sddm

	进入桌面后即为安装常用软件和配置 
	
	
	9 更改桌面为中文：
		1）vim  /etc/locale.gen
		查找 zh_CN.UTF-8 UTF-8 并将注释去掉
		2） locale-gen 
		
	10 添加cn源（可以下载国际源上没有的软件包）
		vim /etc/pacman.conf
		将multilib行和下面那行注释打开
		更改custom 三行  。 注释打开
		Server= https:/mirrors.utsc.edu.cn/archlinuxcn/$arch
		
		保存后注销桌面重新登录

	11 安装输入法
		搜狗bug比较多，我选择谷歌拼音。
		sudo pacman -S fcitx-googlepinyin

		sudo pacman -S fcitx-im  使输入法可以在多种环境下运行
		
		sudo pacman -S fcitx-configtool  配置输入法
		
		注销桌面重新登录 配置输入法，搜索google并使用。

	12 输入法环境变量配置
		切换到登录用户目录
		vim  .xprofile
		编辑
		export GTK_IM_MODULE=fcitx
		export QT_IM_MODULE=fcitx
		export XMODIFIERS=@im=fcitx
		        
		如果想在所有用户下添加可以在如下文件下添加
		vim  /etc/environment

		GTK_IM_MODULE=fcitx
		QT_IM_MODULE=fcitx
		XMODIFIERS=@im=fcitx
	
	
	至此kde可以基本使用了，kde桌面美化，常用软件请自行搜索安装。











	
	