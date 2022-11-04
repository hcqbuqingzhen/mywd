# git原理

### 使用github实操 

git的使用方法日常工作中已经很熟练了 但是git的原理一直没有认真思考过，结合网上资料学习一下。

### 1.暂存区(Stage)和索引(index)

所谓的暂存区`Stage`只是一个简单的索引文件而已。指的是是 `.git/index`文件，理解了索引更加有助于理解git的内部原理。

索引文件里面包含的是文件的目录树，像一个虚拟的工作区，在这个虚拟工作区的目录树中，记录了文件名、文件的最后修改时间、文件长度、文件类型以及最重要的SHA-1值，文件的内容并没有存储在其中。而这个SHA-1值就是某个文件的当前版本号。而文件的具体内容是在.git/objects目录下，你会发现这个目录占用空间比较大，因为它存储着当前项目文件各个版本的内容。

进入objects目录，会看到一些文件夹，先不管info和pack，其他目录名称都是两个英文字母的。每一个文件的每一个版本号都是SHA-1值(40位)，取前2位作为目录名，取后38位作为文件名，所以你会看到这个目录没有具体意义，只是做一个归纳而已，目录下面的文件之间也没什么关系。

在这个目录下，git将其下文件分为四种类型，其中有两种是 tree 类型和 blob 类型，blob类型文件存储的就是我们运行命令增加的文件加上一个特定的文件头，而 tree 类型文件就相当于我们系统下的目录了，里面存储的是多条记录，每一条记录含有一个指向 blob 或子 tree 对象的 SHA-1 指针，并附有该对象的权限模式 (mode)、类型和文件名信息，它和blob类型对象不一样，存储的并非文件的内容。

那么，这个SHA-1是在什么时候生成的呢？这就要明白git add命令做了什么工作。

git add 命令是由两条底层命令实现的：

```shell
git hash-object <filename>
git update-index <filename>

```

运行第一条命令，git将会根据新生成的文件产生一个长度为40的SHA-1哈希字符串，并在.git/objects目录下生成一个以该SHA-1的前两个字符命名的子目录，然后在该子目录下，存储刚刚生成的一个新文件，新文件名称是SHA-1的剩下的38个字符。

第二条命令将会更新.git/index索引，使它指向 objects 目录下新生成的文件。

新建的文件在index中没有记录，如果也不在.gitignore中，那么git status就能检测到；如果修改了文件，那么文件的最后修改时间和index中的不一样，那么git status就能检测到。。。

git add不仅更新索引还生成快照文件，减少git add次数可以减小.git占用的空间。

有时候不想跟踪某些文件，可以将其从index删除掉 git rm --cached filename；当然如果它从未加入到index，那么只需要加入到.gitignore即可。



#### 测试

##### **初始化**

```shell
$ git init
#此时 .git 下没有index文件；.git/objects 下只有info和pack。
#创建a.txt，写入一点内容。
```



![](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/faceimgimage-20221101225314087.png)

```shell
hcq@likepeigen [22:40:57] [~/code/myself/gittest/test] [master]
-> % git status
位于分支 master

尚无提交
未跟踪的文件:
  （使用 "git add <文件>..." 以包含要提交的内容）        a.txt

提交为空，但是存在尚未跟踪的文件（使用 "git add" 建立跟踪）

hcq@likepeigen [22:45:29] [~/code/myself/gittest/test] [master *]
-> % git add . 

hcq@likepeigen [22:45:52] [~/code/myself/gittest/test] [master *]
-> % git status
位于分支 master

尚无提交
要提交的变更：  （使用 "git rm --cached <文件>..." 以取消暂存）        新文件：   a.txt




```

![](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/faceimgimage-20221101225743708.png)

此时可以看到 .git/index 文件，并且 objects 目录下多出了文件夹



##### **再次修改文件**

![](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/faceimgimage-20221101225648743.png)



```shell
hcq@likepeigen [22:54:40] [~/code/myself/gittest/test] [master *]
-> % git status
位于分支 master

尚无提交
要提交的变更：  （使用 "git rm --cached <文件>..." 以取消暂存）        新文件：   a.txt

尚未暂存以备提交的变更：  （使用 "git add <文件>..." 更新要提交的内容）  （使用 "git restore <文件>..." 丢弃工作区的改动）        修改：     a.txt


hcq@likepeigen [22:57:08] [~/code/myself/gittest/test] [master *]
-> % git add . 

```

![](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/faceimgimage-20221101225743708.png)

再次查看 objects 目录，发现又多出了一个目录。到目前为止我们一次都没有提交。

##### **提交**

```shell
hcq@likepeigen [22:57:53] [~/code/myself/gittest/test] [master *]
-> % git commit -m 'first commit'
[master（根提交） f40fd50] first commit
 1 file changed, 2 insertions(+)
 create mode 100644 a.txt
```



![image-20221101230110136](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/faceimgimage-20221101230110136.png)

##### **查看**

commit对象

```shell
-> % git cat-file -p f40fd50     
tree b11b51d45da18e3a4321083bbeb80710efe104aa
author 韩长庆 <1316662395@qq.com> 1667314842 +0800
committer 韩长庆 <1316662395@qq.com> 1667314842 +0800

first commit
```

可以看到 commit对象指向的是tree对象，没有父级parent即代表第一次提交；

查看tree对象的存储内容：

```shell
hcq@likepeigen [23:08:45] [~/code/myself/gittest/test] [master]
-> % git cat-file -p b11b51d       
100644 blob 747d212e5e1f72b974452c0b00359eb444109896    a.txt
```

查看tree对象指向的文件的内容

```shell
hcq@likepeigen [23:10:20] [~/code/myself/gittest/test] [master]
-> % git cat-file -p 747d212       
 aaaaa=0
 bbbb=7%  
```



![image-20221101231531563](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/faceimgimage-20221101231531563.png)



可以发现有如下关系

至此我们看到了 objects 下的三种文件类型，他们的文件名都是 SHA-1：

 blob对象：文件，存储了具体的文件内容。

 tree对象：目录，存储的是目录下的文件和目录的SHA-1值和其他相关信息。 

commit对象：存储着此次commit的信息。



##### 再次修改**a.txt**

![image-20221101232159344](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/faceimgimage-20221101232159344.png)



执行git流程

```shell
hcq@likepeigen [23:19:21] [~/code/myself/gittest/test] [master *]
-> % git add .                 

hcq@likepeigen [23:20:06] [~/code/myself/gittest/test] [master *]
-> % git commit -m 'two commit'
[master 51af4b1] two commit
 1 file changed, 2 insertions(+), 1 deletion(-)

hcq@likepeigen [23:20:17] [~/code/myself/gittest/test] [master]
-> % git cat-file -p 51af4b1       
tree 2d8aca883ac3af54b2d47f447dc32db7223727be
parent f40fd509ac732dd5b509796fa8bc9d7eefd32784
author 韩长庆 <1316662395@qq.com> 1667316017 +0800
committer 韩长庆 <1316662395@qq.com> 1667316017 +0800

two commit

hcq@likepeigen [23:20:43] [~/code/myself/gittest/test] [master]
-> % git cat-file -p 2d8aca88       
100644 blob 9ff67cc14b4bcde3e9b360a61f3fe7979731ba84    a.txt

hcq@likepeigen [23:20:54] [~/code/myself/gittest/test] [master]
-> % git cat-file -p 9ff67cc14b        
 aaaaa=0
 bbbb=7
 cccc=9%   
```

![image-20221101232501580](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/faceimgimage-20221101232501580.png)



如上所示关系

比较第一次提交多了字段

parent f40fd509ac732dd5b509796fa8bc9d7eefd32784

看到 parent 字段，指向的是上一次的commit对象，于是我们知道commit对象之间是通过parent找到上一次的提交。



##### 如何理解**tree**对象



创建 src/java/bb.txt 文件，并编辑。

![image-20221101232818428](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/faceimgimage-20221101232818428.png)



执行一系列git指令

```shell
hcq@likepeigen [23:21:13] [~/code/myself/gittest/test] [master]
-> % git add .                 

hcq@likepeigen [23:46:02] [~/code/myself/gittest/test] [master *]
-> % git commit -m '3 commit add b.txt'
[master 2ef1dab] 3 commit add b.txt
 1 file changed, 1 insertion(+)
 create mode 100644 src/java/bb.txt

hcq@likepeigen [23:46:38] [~/code/myself/gittest/test] [master]
-> % git cat-file -p 2ef1dab           
tree 3bd3eec80ec49c41765a0f8fdb912d858828aa92
parent 51af4b163fb369a216c3fb088581a0a3a3152e06
author 韩长庆 <1316662395@qq.com> 1667317598 +0800
committer 韩长庆 <1316662395@qq.com> 1667317598 +0800

3 commit add b.txt

hcq@likepeigen [23:47:21] [~/code/myself/gittest/test] [master]
-> % git cat-file -p 3bd3eec       
100644 blob 9ff67cc14b4bcde3e9b360a61f3fe7979731ba84    a.txt
040000 tree 0ea1a0c41a51de6336527c8ed9c1db2b25ecff8e    src

hcq@likepeigen [23:47:42] [~/code/myself/gittest/test] [master]
-> % git cat-file -p 0ea1a0c41       
040000 tree 6e63a612185ec0f6903041a3947fc93a231110cd    java

hcq@likepeigen [23:48:20] [~/code/myself/gittest/test] [master]
-> % git cat-file -p 6e63a61218         
100644 blob b34916336199bfbdee38687d03dad7efb9b3a51b    bb.txt

hcq@likepeigen [23:48:41] [~/code/myself/gittest/test] [master]
-> % git cat-file -p b349163          
bbbb=90%   
```



![image-20221101235056415](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/faceimgimage-20221101235056415.png)



此时发现 tree 就是目录的意思，blob就是文件的意思。当前目录下有多个目录就有多个tree字段。

至此我们大致可以理解为什么commit之后会多出多个文件，一个是commit对象，一个是当前commit时项目的根目录tree对象，如果有新建目录，还会产生tree对象（而在 git add 的时候则只会产生blob对象），这些tree和blob展示了当前version下的文件目录结构全量信息。

```tips
比如你修改了一个文件，那么它所处的当前目录以及上面的所有目录都会改变，所以会生成多个 tree 对象
原先是 treeA -> treeB -> treeC -> treeD
你把 treeD 目录下删了一个文件，就变成了
treeA2 -> treeB2 -> treeC2 -> treeD2
```

git正是拷贝index的这些目录树和文件的SHA-1等信息到commit对象而生成git的一个提交，即commit对象，commit对象保存的提交完整的记录了当前所有已跟踪文件的快照。所以你所提交的项目来自于index。



**简而言之，文件索引即暂存区，建立了文件和.git/objects目录下的对象实体之间的映射关系。**



通过前面的介绍，我们对 工作区 --> 暂存区的过程已经很清楚了，要知道index只有一个，我们在切换分支，版本，tag等操作的时候，随着HEAD的变化，会对应到不同的commit对象，此时会有一个逆向的过程，那就是从commit对象来恢复index，因为commit对象保存着全量的tree对象，所以这个过程是很明确的，于是index被改写，最后再从index将目录结构和文件检出到工作区，于是我们才能看到指定的commit时的代码。

下面一张图可以很好的说明关系

![image-20221102113038077](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/faceimgimage-20221102113038077.png)



### 2.HEAD是什么

HEAD指的就是 `.git/HEAD` 文件，它存储着当前working directory所处的某次[commit](https://so.csdn.net/so/search?q=commit&spm=1001.2101.3001.7020)，打开文件内容为

```shell
ref: refs/heads/master
```



refs目录下存储的是仓库和tags，每个仓库下又有分支，每个tags下又有tag，一个tag对应的某次commit。



```shell
存储 local master 分支的最新commit对象的SHA-1
refs/heads/master

存储远程仓库 master 分支的最新commit对象的SHA-1
refs/remotes/origin/master

存储tag的SHA-1
tags/xxx
```



![image-20221102114055945](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/faceimgimage-20221102114055945.png)



**HEAD 是当前分支引用的指针，**它总是指向某次commit，默认是上一次的commit。 这表示 HEAD 将是下一次提交的父结点。 通常，可以把 HEAD 看做你的上一次提交的快照。当然HEAD的指向是可以改变的，比如你提交了commit，切换了仓库，分支，或者回滚了版本，切换了tag等。

### 3.git diff详解

#### 比较工作区和暂存区的差别

```shell
git diff 
或者
git diff filename
```

#### 比较暂存区和本库的差别

```shell
git diff --cached 
或者
git diff --cached  filename

(Git 1.6.1 及更高版本还允许使用 git diff --staged，效果是相同的)
```

#### 比较工作区和版本库的差别

```shell
git diff HEAD 
```

#### 比较两个分支上最新的提交

```shell
git diff topic master

```

#### 比较上次commit和上上次commit

```shell
git diff HEAD^ HEAD
```

#### 比较两个具体commit之间的差异

```shell
git diff 818c5faf28d0a0e5c8133dbd77dd24e6e70db9bf 2e1b4bced0f0ce2c20362789be2878b36c6910f7
```

#### 自从某个版本之后都改的了什么

```shell
git diff [version tag]

git diff f2b85bf7f7516a6a6a0768e44266d09414b03a2e

```

#### 比较两个分支

```shell
git diff [branchA]…[branchB]

```

git-diff在idea中常用来比较不同。



### 4.git log指令

测试

```shell
commit 18331acae3fe86fa64d9722731381b197e4f9cb7 (HEAD -> master)
Author: 韩长庆 <1316662395@qq.com>
Date:   Tue Nov 1 23:58:51 2022 +0800

    4 commit inster  a.txt

commit 2ef1dab35250997cba7c360b85e54c17e13f3cc3
Author: 韩长庆 <1316662395@qq.com>
Date:   Tue Nov 1 23:46:38 2022 +0800

    3 commit add b.txt

commit 51af4b163fb369a216c3fb088581a0a3a3152e06
Author: 韩长庆 <1316662395@qq.com>
Date:   Tue Nov 1 23:20:17 2022 +0800

    two commit

commit f40fd509ac732dd5b509796fa8bc9d7eefd32784
Author: 韩长庆 <1316662395@qq.com>
Date:   Tue Nov 1 23:00:42 2022 +0800

    first commit
```



### git log --oneline 简化输出

```shell
18331ac (HEAD -> master) 4 commit inster  a.txt
2ef1dab 3 commit add b.txt
51af4b1 two commit
f40fd50 first commit
```

##### 指定输出行数

```shell
$ git log --pretty=oneline -3
818c5faf28d0a0e5c8133dbd77dd24e6e70db9bf (HEAD -> master) aaaaaaa
2e1b4bced0f0ce2c20362789be2878b36c6910f7 add t4
8262ea4e39ea80dc56056a667e9dbdcd235efc08 add t3
```

##### 限定指定日期范围的log

```
$ git log --pretty=oneline --after='12-8-2020 00:00:00'
818c5faf28d0a0e5c8133dbd77dd24e6e70db9bf (HEAD -> master) aaaaaaa

```

##### 查看某次提交的改动

`git show`命令同`git log -p`输出类似，只不过它只显示一个commit的内容，如果不指定commit hash, 它默认输出HEAD指向commit的内容.

指定某个提交

```shell
git show 6f43203cf463dc5320916f96abef0f1ad63428fd
```



**大部分情况下，idea上的git log更加直观和好用。**



### 5.git reset详解

HEAD是指向某个[commit](https://so.csdn.net/so/search?q=commit&spm=1001.2101.3001.7020)的指针，既然如此，那么我们就可以操作HEAD来使其指向特定的commit。

要知道每个commit对象保存着全量的tree结构，从这个tree可以恢复与之对应的index，而从index可以检出此时的文件到working directory。所以我们操作HEAD之后会有附加的功能，那就是恢复index，恢复working directory。所以 git reset 也就伴随有“回滚”，“撤销”的能力。

主要参数

```
--soft                reset only HEAD 设置HEAD
--mixed               reset HEAD and index 设置HEAD，重置index
--hard                reset HEAD, index and working tree 设置HEAD，重置index，检出working directory
```

#### 从暂存区取消刚才add的文件

```
git reset HEAD <file>

```

 git ls-files

git 处于clean状态，查看暂存区种有那些文件



##### 场景1

修改 a.txt 文件，并 add，此时为带提交的状态，如果想 t1.txt 恢复到 Unstage 状态，可以使用如下命令撤销此次 add 。

```
git reset HEAD a.txt
```

##### 场景2

在一个新项目的时候，我们往往会先将不需要跟踪的文件加入到 .gitignore 中，但是它的弊端在于只要是存在于 Index 中的文件，即使你将它加入到 .gitignore 中，它还是会被跟踪的，所以这个 .gitignore 只适合用在初始化项目的时候。

假设你第一次将某个文件add，还没有commit，此时你发现这个文件应该被 ignore ，此时可以使用 git reset HEAD filename 来将其移出index。然后在 .gitignore 中标记。可见这个命令依然比较鸡肋。

先不管它有没有价值，来思考一下它的原理是什么？

还是回到上面的解释，git reset HEAD filename 虽然没有移动HEAD，但是git还是会取执行后续的操作，因为默认模式是 --mixed ，也就是需要恢复 index，所以 index 就被恢复到上一次commit时的状态了。

从 index 中删除某个文件的命令应该是 git rm --cached filename

#### 版本回滚



```shell
HEAD		表示当前版本
HEAD^		上一个版本
HEAD^^		上上一个版本
HEAD~100	上100个版本，通用的
版本号		  指定版本
```



结合 git log 和 git reflog 指令 可任意在不同版本之间切换

### 6.git checkout

checkout 本意是检出的意思，也就是将某次commit的状态检出到工作区；

所以它的过程是先将`HEAD`指向某个分支的最近一次commit，然后从commit恢复index，最后从index恢复工作区。

#### 切换分支

git checkout branchname

`git checkout -b branchname` 创建并切换到新的分支.
这个命令是将`git branch newbranch`和`git checkout newbranch`合在一起的结果。



#### 放弃修改

如果不指定切换到哪个分支，那就是**切换到当前分支**，虽然HEAD的指向没有变化，但是后面的两个恢复过程依然会执行，于是就可以理解为放弃index和工作区的变动。

**但是出于安全考虑 git 会保持 index 的变动不被覆盖。**



##### 只放弃工作区的改动，index 保持不变，

其实就是从当前 index 恢复 工作区：

放弃工作区中全部的修改
`git checkout .`

放弃工作区中某个文件的修改：
`git checkout -- filename`



**相当于从最后一次add处覆盖。**

##### 强制放弃 index 和 工作区 的改动：

git checkout -f

这是不可逆的操作，会直接覆盖。**相当于从commit处覆盖。**



### 7. git rm



git rm 命令可以删除文件，那么它删除的是 index 还是 工作区呢，和手动删除文件有什么区别呢？

Remove files from the working tree and from the index

说明 git rm 既能删除 Index 也能删除工作区的文件。



只要某个文件在 index 或者 工作区 有变动都是不能删除的，必须加上 -f 参数。

对于没有变动的文件

使用git rm 可直接删除，指的是index中和文件本身都会删除。

另外，--cached 参数会将文件从 index 删除，变成 Untracked 状态，依然是没有提交，接着上面的场景。



实验见下

```shell
cq@likepeigen [15:42:47] [~/code/myself/gittest/test] [master]
-> % git rm a.txt
错误：如下文件有本地修改：    a.txt
（使用 --cached 保留本地文件，或用 -f 强制删除）
hcq@likepeigen [15:43:30] [~/code/myself/gittest/test] [master *]
-> % git add .   

hcq@likepeigen [15:44:13] [~/code/myself/gittest/test] [master *]
-> % git rm a.txt
错误：下列文件索引中有变更    a.txt
（使用 --cached 保留本地文件，或用 -f 强制删除）
hcq@likepeigen [15:44:18] [~/code/myself/gittest/test] [master *]
-> % git checkout -f

hcq@likepeigen [15:45:08] [~/code/myself/gittest/test] [master]
-> % git rm a.txt   
rm 'a.txt'

hcq@likepeigen [15:45:15] [~/code/myself/gittest/test] [master *]
-> % git status  
位于分支 master
要提交的变更：  （使用 "git restore --staged <文件>..." 以取消暂存）        删除：     a.txt


hcq@likepeigen [15:45:24] [~/code/myself/gittest/test] [master *]
-> % git log          

hcq@likepeigen [15:45:32] [~/code/myself/gittest/test] [master *]
-> % 

hcq@likepeigen [15:45:32] [~/code/myself/gittest/test] [master *]
-> % git-log

hcq@likepeigen [15:46:35] [~/code/myself/gittest/test] [master *]
-> % git checkout -f

hcq@likepeigen [15:46:39] [~/code/myself/gittest/test] [master]
-> % git rm --cached a.txt
rm 'a.txt'

hcq@likepeigen [15:47:11] [~/code/myself/gittest/test] [master *]
-> % git status           
位于分支 master
要提交的变更：  （使用 "git restore --staged <文件>..." 以取消暂存）        删除：     a.txt

未跟踪的文件:
  （使用 "git add <文件>..." 以包含要提交的内容）        a.txt


hcq@likepeigen [15:47:22] [~/code/myself/gittest/test] [master *]
-> % git checkout -f      

hcq@likepeigen [15:47:45] [~/code/myself/gittest/test] [master]
-> % git status
位于分支 master
无文件要提交，干净的工作区

```



### 8. 一般指令

git库所在的文件夹中的文件大致有4种状态
**Untracked**
未跟踪，此文件在文件夹中，但并没有加入到git库，不参与版本控制。通过 git add 将状态变为 Staged。

**Modified**
文件已修改，仅仅是修改，并没有进行其他的操作。这个文件也有两个去处，通过
git add filename 可进入暂存 Staged 状态，
git checkout – filename 则丢弃修改，返回到 Unmodify 状态，也就是从库中取出文件，覆盖当前修改。

**Staged**
暂存状态。
可以执行 git reset HEAD filename 取消暂存，文件状态为 Untracked 状态。
可以执行 git commit 将修改同步到库中，这时库中的文件和本地文件又变为一致，文件为 Unmodify 状态。

**Unmodify**
文件已经入库，未修改，即版本库中的文件快照内容与文件夹中完全一致，这种类型的文件有两种去处。
如果它被修改而变为 Modified；
可以使用 git rm filename 移出版本库，并删除文件，但是还没提交！！
可以使用 git rm --cached filename 移出版本库，成为 Untracked，但是还没提交！！



#### 其他指令

###### git reflog

> 查看仓库的操作历史

###### git tag

> 为本地仓库创建tag

###### git remote



> git remote add [alias] [url]
> 添加一个新的remote repo，一般一个本地仓库对应一个远程仓库，并且使用 origin 作为名称，即
> git remote add origin url
>
> 如果别名alias已经存在了则会报错，可以先删除再来加，也可以直接修改url。
> 远程仓库是存储在 .git/refs/remotes 目录下。
>
> git remote rm [alias]
> 删除一个存在的remote alias。
>
> git remote rename [old-alias] [new-alias]
> 重命名
>
> git remote set-url [alias] [url]
> 更新url. 可以加上—push和fetch参数,为同一个别名set不同的存取地址

###### git fetch



> download new branches and data from a remote repository.
>
> 拉取指定远程仓库上的指定分支的代码，比如 origin master。
>
> 首先会对比本地的 .git/refs/remotes/origin/master 文件中保存的 commitID 和线上的 master 分支的最新的 commitID 对比，如果不一致，则将这些文件下载下来。下载下来的文件依然放在 .git/objects 下面，然后更新 .git/refs/remotes/origin/master 文件到最新的 commitID。
>
> 可以git fetch [alias]取某一个远程repo,也可以git fetch --all取到全部repo。
> 它们和本地分支一样(可以看diff,log等,也可以merge到其他分支),但是Git不允许你checkout到它们

###### git pull

> push your new branches and data to a remote repository.
>
> git push [alias] [branch]
> 将会把当前分支merge到alias上的[branch]分支.如果分支已经存在,将会更新,如果不存在,将会添加这个分支.
> 如果有多个人向同一个remote repo push代码, Git会首先在你试图push的分支上运行git log,检查它的历史中是否能看到server上的branch现在的tip,如果本地历史中不能看到server的tip,说明本地的代码不是最新的,Git会拒绝你的push,让你先fetch,merge,之后再push,这样就保证了所有人的改动都会被考虑进来。
>
> 第一次push的时候一般加上 -u 参数，这样push成功后，Git会在你本地将当前提交的分支和 [alias] [branch] 做一个绑定，这样以后的 push, pull, status 操作就默认指向了 [alias] [branch]，而不用每次都去指定



###### git branch

> git branch可以用来列出分支,创建分支和删除分支.
> git branch -v可以看见每一个分支的最后一次提交.
> git branch: 列出本地所有分支,当前分支会被星号标示出.
> git branch (branchname): 创建一个新的分支(当你用这种方式创建分支的时候,分支是基于你的上一次提交建立的).
> git branch -d (branchname): 删除一个分支.
> 删除remote的分支:
> git push (remote-name) :(branch-name): delete a remote branch.
> 这个是因为完整的命令形式是:
> git push remote-name local-branch:remote-branch
> 而这里local-branch的部分为空,就意味着删除了remote-branch

###### git merge

> 把一个分支merge进当前的分支.
> git merge [alias] [branch]
>
> 如果出现冲突,需要手动修改,可以用git mergetool.
> 解决冲突的时候可以用到git diff,解决完之后用git add添加,即表示冲突已经被resolved



###### git rebase

把本地未push的分叉提交历史整理成直线。
rebase的目的是使得我们在查看历史提交的变化时更容易，因为分叉的提交需要三方对比。



### 9 分支管理



###### branch

查看分支的情况，前面带*号的就是当前分支
git branch

创建分支
git branch 分支名

删除分支
git branch -d 分支名

checkout
切换当前分支到指定分支
git checkout 分支名

创建分支并切换到创建的分支
git checkout -b 分支名

###### merge

合并某分支的内容到当前分支
git merge 分支名

如果两个分支同时进行了同一个文件的修改和提交，在merge时就会产生冲突，首先要手动打开文件解决冲突，再提交。

查看分支合并图
git log --graph

红色和绿色的虚线分别代表两个分支。

###### git merge 的原理：

我们知道分支文件中存储的是当前分支的最新一次提交的commitID，也就是版本号，而每一个版本号对应的 objects 文件中都存储着 parent 版本号（首次提交没有 parent），以此将版本串起来，每一个分支都有自己的串。

比如将分支A合并到分支B，其实就意味着使分支B和分支A的内容完全一致，那么要达到这个目的最快的方式就是将分支A中的最新的commitID复制到分支B的文件中，这样分支B也就拥有了分支A的串，就达到了合并的效果。



我们发现只要修改了同一个文件的同一行就会产生冲突，此时需要手动解决冲突。





### 10 git stash

git stash 会保存工作区和暂存区的内容。

git stash 依然会在object中保存对象文件，类似commit。



无论在工作区还是暂存区，调用git stash 命令都会使当前工作目录的文件回到head。

调用git stash pop会使暂存的文件返回**工作区**，需要重新add.



#### 查看

```shell
列出栈中的所有内容
$ git stash list
stash@{0}: On master: cache master

显示某个隐藏的具体内容
$ git stash show stash@{0}
q/w/t4.txt | 1 +
t1.txt     | 3 ++-
2 files changed, 3 insertions(+), 1 deletion(-)

```



#### 读取

```shell
调用任意一个隐藏内容，但是并没有删除栈中的记录
$ git stash apply stash@{0}

取出栈中的第一个内容（栈是先进后出），且删除栈中的记录
$ git stash pop

从最新的stash创建分支
$ git stash branch

应用场景：当储藏了部分工作，暂时不去理会，继续在当前分支进行开发，后续想将stash中的内容恢复到当前工作目录时，如果是针对同一个文件的修改（即便不是同行数据），那么可能会发生冲突，恢复失败，这里通过创建新的分支来解决。可以用于解决stash中的内容和当前目录的内容发生冲突的情景。

删除某一个记录
$ git stash drop stash@{0}

清除全部记录
$ git stash clear

```

如果从stash中恢复的内容和当前目录中的内容发生了冲突，也就是说，恢复的内容和当前目录修改了同一行的数据，那么会提示报错，需要解决冲突，可以通过创建新的分支来解决冲突。