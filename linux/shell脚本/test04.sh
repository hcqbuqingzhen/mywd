#printf 命令的语法：

# printf  format-string  [arguments...]

echo "Hello, Shell"
#Hello, Shell
printf "Hello, Shell\n"
#Hello, Shell

# 类似于c语言中的格式化
printf "%-10s %-8s %-4s\n" 姓名 性别 体重kg  
printf "%-10s %-8s %-4.2f\n" 郭靖 男 66.1234 
printf "%-10s %-8s %-4.2f\n" 杨过 男 48.6543 
printf "%-10s %-8s %-4.2f\n" 郭芙 女 47.9876 