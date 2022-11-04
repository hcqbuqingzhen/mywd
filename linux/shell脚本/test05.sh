# 和Java、PHP等语言不一样，sh的流程控制不可为空

a=10
b=20
if [ $a == $b ]
then
   echo "a 等于 b"
elif [ $a -gt $b ]
then
   echo "a 大于 b"
elif [ $a -lt $b ]
then
   echo "a 小于 b"
else
   echo "没有符合的条件"
fi

# 和test结合
num1=$[2*3]
num2=$[1+5]
echo $num1
if test $num1 -eq $num2
then
    echo '两个数字相等!'
else
    echo '两个数字不相等!'
fi

#for 循环
#for循环一般格式为：
for loop in 1 2 3 4 5
do
    echo "The value is: $loop"
done
# 也可以对string操作
for str in 'This is a string'
do
    echo $str
done

# while

int=1
#while [[ $int -lt 5 ]]
while(($int<=5))
do
    echo $int
    #int=`expr $int + 1`
    let int++
done

# until

a=0

until [ ! $a -lt 10 ]
do
   echo $a
   a=`expr $a + 1`
done

# case
# case 数字 在in中,匹配到1,则执行到;;再退出. 模式要以")" 结束 模式支持正则表达式。
aNum=1
case $aNum in
    1)  echo '你选择了 1'
    ;;
    2)  echo '你选择了 2'
    ;;
    3)  echo '你选择了 3'
    ;;
    4)  echo '你选择了 4'
    ;;
    *)  echo '你没有输入 1 到 4 之间的数字'
    ;;
esac

# break 和continue
# 和其他语言一样
