
# 定义变量和输出变量
# 字符串和数组类型的使用
name="哈哈哈哈"
echo ${name}
echo $name
myurl='duwhgfuwqoidfiwfiwf'
youurl="hell,${name}.你是个傻逼"
length=`expr ${#myurl} + ${#youurl} `
str=${myurl:1:6}
index=`expr index "$youurl" e `
echo ${myurl}
echo ${youurl}
echo ${length}
echo ${index}

# shell数组

array=(1 2 3 4)
echo ${array[2]}
#使用 @ 符号可以获取数组中的所有元素，例如：
echo ${#array[@]}
