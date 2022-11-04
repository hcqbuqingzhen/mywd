##
#原生bash不支持简单的数学运算，但是可以通过其他命令来实现，例如 awk 和 expr，expr 最常用。
#expr 是一款表达式计算工具，使用它能完成表达式的求值操作。
#表达式和运算符之间要有空格，例如 2+2 是不对的，必须写成 2 + 2，这与我们熟悉的大多数编程语言不一样。
#完整的表达式要被 ` ` 包含，注意这个字符不是常用的单引号，在 Esc 键下边。
var=`expr 2 + 2 `
echo $var

# 算术运算符
a=10
b=20
val=`expr ${a} + ${b}`
echo ${val}

val='expr  ${a} - ${b}'
echo ${val}

val='expr  ${a} \* ${b}'
echo ${val}

val='expr  ${a} % ${b}'
echo ${val}

val='expr  ${a} / ${b}'
echo ${val}

if [ ${a} == ${b} ]
then 
    echo "a=b"
fi

if [ ${a} != ${b} ]
then 
    echo "a=b"
fi

# 比较运算符

if [ ${a} -eq ${b} ]
then
    echo " ${a} -eq ${b} : a等于b"
else
    echo " ${a} -eq ${b} : a不等于b"
fi

if [ ${a} -ne ${b} ]
then 
    echo " ${a} -ne ${b} : a不等于b"
else
    echo " ${a} -ne ${b} : a等于b"
fi

if [ ${a} -gt ${b} ]
then 
    echo " ${a} -gt ${b} : a大于b"
else
    echo " ${a} -gt ${b} : a不大于b"
fi

if [ ${a} -lt ${b} ]
then 
    echo " ${a} -lt ${b} : a不大于b"
else
    echo " ${a} -lt ${b} : a大于b"
fi

if [ ${a} -ge ${b} ]
then 
    echo " ${a} -ge ${b} : a大于等于b"
else
    echo " ${a} -ge ${b} : a不大于等于b"
fi

if [ ${a} -le ${b} ]
then 
    echo " ${a} -le ${b} : a大于等于b"
else
    echo " ${a} -le ${b} : a不大于等于b"
fi

# 布尔运算符
# ! 非
# -o 或
# -a 与

if [ ! ${a} ]
then 
    echo " ${a} != ${b} : a不等于b"
else
    echo " ${a} == ${b} : a等于b"
fi

if [ ${a} -gt 100 -a ${b} -lt 100 ]
then 
    echo " a>100同时a<100 返回true"
else
    echo " a>100同时a<100 返回false"
fi

if [ ${a} -gt 100 -o  ${b} -lt 100 ]
then 
    echo " a>100或b<100 返回true"
else
    echo " a>100或b<100 返回false"
fi

# 逻辑运算符
# $$ and
# || or 
if [[ ${a} -gt 100 && ${b} -lt 100 ]]
then 
    echo " a>100同时a<100 返回true"
else
    echo " a>100同时a<100 返回false"
fi

if [[ ${a} -gt 100 ||  ${b} -lt 100 ]]
then 
    echo " a>100或b<100 返回true"
else
    echo " a>100或b<100 返回false"
fi

# 字符串运算符
# = 检测两个字符串是否相等，相等返回 true。
# != 检测两个字符串是否相等，不相等返回 true。
# -z 检测字符串长度是否为0，为0返回 true。
# -n 检测字符串长度是否不为 0，不为 0 返回 true。
# $ 检测字符串是否为空，不为空返回 true。

c="abc"
d="efg"
if [ $c = $d ]
then 
    echo "$c = $b :c等b"
else
    echo "$c = $b :c不等b"
fi

if [ $c != $d ]
then 
    echo "$c = $b :c不等b"
else
    echo "$c = $b :c等b"
fi

if [ -z $d ]
then 
    echo "$c = $b :d等0"
else
    echo "$c = $b :d不等0"
fi

if [ -n $d ]
then  
    echo "$c = $b :d长度不等0"
else
    echo "$c = $b :d等0"
fi

if [ $d ]
then 
    echo "$c = $b :d不等空"
else
    echo "$c = $b :d等空"
fi

# 文件测试符
# 文件测试运算符用于检测 Unix 文件的各种属性。
# -b file	检测文件是否是块设备文件，如果是，则返回 true。
# -c file	检测文件是否是字符设备文件，如果是，则返回 true。
# -d file	检测文件是否是目录，如果是，则返回 true。
# -f file	检测文件是否是普通文件（既不是目录，也不是设备文件），如果是，则返回 true。
# -g file	检测文件是否设置了 SGID 位，如果是，则返回 true。
# -k file	检测文件是否设置了粘着位(Sticky Bit)，如果是，则返回 true。
# -p file	检测文件是否是有名管道，如果是，则返回 true。
# -u file	检测文件是否设置了 SUID 位，如果是，则返回 true。
# -r file	检测文件是否可读，如果是，则返回 true。
# -w file	检测文件是否可写，如果是，则返回 true。
# -x file	检测文件是否可执行，如果是，则返回 true。
# -s file	检测文件是否为空（文件大小是否大于0），不为空返回 true。
# -e file	检测文件（包括目录）是否存在，如果是，则返回 true。