gitlab和jenkins都是软件
配置运行环境
下载安装即可
http://mirror.xmission.com/jenkins/updates/update-center.json
jenkins安装后 访问显示错误页面
需要配置下一步
    修改启动用户为root
    [root@jenkins ~]# vim /etc/sysconfig/jenkins
    JENKINS_USER="root"