# jvm内存模型 #
## 1.虚拟机栈
## 2.程序计数器
程序计数器和虚拟机栈是线程私有的
## 3.本地方法栈
主要用于处理本地方法栈
## 4.堆
对象的存储空间，jvm管理的空间最大的一块内存。
### 4.1 堆空间划分
    堆空间可以划分为新生代和老年代，与之相对的有Eden空间，From Survivor空间和ToSurvivor空间。
    new 对象的步骤
    1. 在堆内存中创建对象实例
    2. 为成员变量赋初始值
    3. 将对象的引用返回
    
    堆内存分配内存两种算法
    1. 指针碰撞：堆中内存空间由一个指针分割，一侧为使用，一侧为空闲。
    	对应的gc算法 ：serial parnew 
    2. 空闲列表：堆中内存已使用和未使用空间交织在一起，有一列表记录空间使用状况。new 对象时会在空闲列表里分配内存，同时修改列表。
    
    对象的结构
    1. 对象头
    2. 实例数据
    3. 对齐填充
    
    访问对象的方式
    1. 使用句柄的方式
    2. 使用直接指针的方式 
## 5.方法区（元数据区）
命令行工具：jmap jstat jcmd
图形化工具：jmc jhat jv 

## 6.运行时常量池
方法区的一部分内容

但

## 7.直接内存