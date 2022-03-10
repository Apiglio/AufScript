# AufScript
just a toy, but interesting.

+ TAuf can be said as a command-line class in "AufScript"
+ it contains some "asm-like function" for basic calculation and process control
+ use TAufScript.add_func( name, func_ptr, args_str, tip_str) to add similar function


<br><br><br><br><br><br><br><br>


# built-in function:
<br>**set** option,value 代码窗运行设置
<br>**version**          显示解释器版本号
<br>**help**             显示帮助
<br>**deflist**          显示定义列表
<br>**ramex** -option/arv,filename       将内存导出到ram.var
<br>**ramim** filename [,var [,-f]]      从文件中载入数据到内存
<br>**sleep** n          等待n毫秒
<br>**pause**            暂停
<br>**beep** freq,dura   以freq的频率蜂鸣dura毫秒
<br>**cmd** command      调用命令提示行
<br>**hex** var          输出标准变量形式的十六进制
<br>**hexln** var        输出标准变量形式的十六进制并换行
<br>**print** var        输出变量var
<br>**println** var      输出变量var并换行
<br>**echo** expr        解析表达式 
<br>**echoln** expr      解析表达式并换行
<br>**cwln**             换行
<br>**clear**            清屏
<br>**of** [filename]    改为输出到文件
<br>**os**               改为输出到屏幕，同时保存已经输出到文件的内容
<br>**mov** v1,v2        将v2值赋值给v1
<br>**add** v1,v2        将v1和v2的值相加并返回给v1
<br>**sub** v1,v2        将v1和v2的值相减并返回给v1
<br>**mul** v1,v2        将v1和v2的值相乘并返回给v1
<br>**div** v1,v2        将v1和v2的值相除并返回给v1
<br>**mod** v1,v2        将v1和v2的值求余并返回给v1
<br>**rand** v1,v2       将不大于v2的随机整数返回给v1
<br>**swap** v1          将v1字节倒序
<br>**fill** var,byte    用byte填充var
<br>**loop** :label/ofs,times[,st]       简易循环times次
<br>**jmp** :label/ofs   跳转到相对地址
<br>**call** :lable/ofs  跳转到相对地址，并将当前地址压栈
<br>**ret**              从栈中取出一个地址，并跳转至该地址
<br>**load** filename    加载运行指定脚本文件
<br>**fend**             从加载的脚本文件中跳出
<br>**halt**             无条件结束
<br>**end**              有条件结束，根据运行状态转译为ret, fend或halt
<br>**define** name,expr 定义一个以@开头的局部宏定义
<br>**rendef** old,new   修改一个局部宏定义的名称
<br>**deldef** name              删除一个局部宏定义的名称
<br>**ifdef** name               如果有定义则跳转
<br>**ifndef** name              如果没有定义则跳转
<br>**var** type,name,size       创建一个ARV变量
<br>**unvar** name               释放一个ARV变量
<br>**cje** v1,v2,:label/ofs     如果v1等于v2则跳转
<br>**ncje** v1,v2,:label/ofs    如果v1不等于v2则跳转
<br>**cjm** v1,v2,:label/ofs     如果v1大于v2则跳转
<br>**ncjm** v1,v2,:label/ofs    如果v1不大于v2则跳转
<br>**cjl** v1,v2,:label/ofs     如果v1小于v2则跳转
<br>**ncjl** v1,v2,:label/ofs    如果v1不小于v2则跳转
<br>**cjec** v1,v2,:label/ofs    如果v1等于v2则跳转，并将当前地址压栈
<br>**ncjec** v1,v2,:label/ofs   如果v1不等于v2则跳转，并将当前地址压栈
<br>**cjmc** v1,v2,:label/ofs    如果v1大于v2则跳转，并将当前地址压栈
<br>**ncjmc** v1,v2,:label/ofs   如果v1不大于v2则跳转，并将当前地址压栈
<br>**cjlc** v1,v2,:label/ofs    如果v1小于v2则跳转，并将当前地址压栈
<br>**ncjlc** v1,v2,:label/ofs   如果v1不小于v2则跳转，并将当前地址压栈
<br>**cjs** s1,s2,:label/ofs     如果s1相等s2则跳转
<br>**ncjs** s1,s2,:label/ofs    如果s1不相等s2则跳转
<br>**cjsc** s1,s2,:label/ofs    如果s1相等s2则跳转，并将当前地址压栈
<br>**ncjsc** s1,s2,:label/ofs   如果s1不相等s2则跳转，并将当前地址压栈
<br>**cjsub** sub,str,:label/ofs 如果str包含sub则跳转
<br>**ncjsub** sub,str,:label/ofs        如果str不包含sub则跳转
<br>**cjsubc** sub,str,:label/ofs        如果str包含sub则跳转，并将当前地址压栈
<br>**ncjsubc** sub,str,:label/ofs       如果str不包含sub则跳转，并将当前地址压栈
<br>**cjsreg** reg,str,:label/ofs        如果str符合reg则跳转
<br>**ncjsreg** reg,str,:label/ofs       如果str不符合reg则跳转
<br>**cjsregc** reg,str,:label/ofs       如果str符合reg则跳转，并将当前地址压栈
<br>**ncjsregc** reg,str,:label/ofs      如果str不符合reg则跳转，并将当前地址压栈
<br>**str** #[],var      将var转化成字符串存入#[]
<br>**val** $[],str      将str转化成数值存入$[]
<br>**srp** #[],old,new  将#[]中的old替换成new
<br>**gettimestr** var   显示当前时间字符串或存入字符变量var中
<br>**getdatestr** var   显示当前日期字符串或存入字符变量var中
<br>**settimer**         初始化计时器
<br>**gettimer** var     获取计时器度数
<br>**waittimer** var    等待计时器达到var
<br>**readf** var,filename       读取文件并保存至var
<br>**writef** var,filename      将var保存至文件
<br>**getbytes** var,idx,len     截取变量var中从idx起的len个字节到@prev_res
<br>**setbytes** var,idx,src     将变量src保存到变量var的第idx个字节，超出部分不保存
<br>**cmp** v1,v2,out    比较
<br>**shl** var,bit      左移
<br>**shr** var,bit      右移
<br>**not** var          位非
<br>**and** v1,v2        位与
<br>**or** v1,v2         位或
<br>**xor** v1,v2        异或
<br>**ofs** v1,v2,threshold,out  差值位计数
<br>**h_add** #[],#[]            高精加
<br>**h_sub** #[],#[]            高精减
<br>**h_mul** #[],#[]            高精乘
<br>**h_divreal** #[],#[]        高精实数除
