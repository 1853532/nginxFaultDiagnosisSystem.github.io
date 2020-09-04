#!/bin/bash
echo -e  "Fault Injection Tool - fit V0.1"

usage()
{
	echo -e  "Usage: `basename $0` [options]"
	echo -e "-t [k|u]"
	echo -e "\tk：内核态"
	echo -e "\tu：用户态"
	echo -e "-b [BIN-PATH]"
	echo -e "\tBIN-PATH：二进制可执行文件路径，对用户态函数/代码行进行故障注入时需要设定二进制可执行文件路径"
	echo -e "-f [FUNCTION]"
	echo -e "\tFUNCTION：故障注入函数或代码行"
	echo -e "-i [r|p|s]"
	echo -e "\tr：函数返回值故障"
	echo -e "\tp：函数参数故障"
	echo -e "\ts：代码行参数故障"
	echo -e "-r [RETURN-VALUE]"
	echo -e "\tRETURN-VALUE：函数返回值故障的错误值"
	echo -e "-p [PARAMETER-NAME]"
	echo -e "\tPARAMETER-NAME：函数或代码行参数的故障参数名"
	echo -e "-v [PARAMETER-VALUE]"
	echo -e "\tPARAMETER-VALUE：函数或代码行参数的故障参数值"
	echo -e "-d [FUNCTION]"
	echo -e "\tFUNCTION：故障注入生效区间开始的函数名"
	echo -e "-y [FUNCTION]"
	echo -e "\tFUNCTION：故障注入生效区间开始的函数名"
	echo -e "-s [SECOND]"
	echo -e "\tSECOND：故障注入延迟生效的时间（秒）"
	echo -e "-l [SECOND]"
	echo -e "\tSECOND：故障注入的生效持续时间（秒）"
	echo -e "-c [PROCESS-NAME]"
	echo -e "\tPROCESS-NAME：故障注入的目标进程名"
	echo -e "-x [PID]"
	echo -e "\tPID：故障注入的目标进程PID"
	echo -e "-q [FUNCTION1,FUNCTION2,FUNCTION3,...]"
	echo -e "\tFUNCTION1,FUNCTION2,FUNCTION3,...：函数序列，配合-k选项设定故障注入触发条件"
	echo -e "-k [NUMBER]"
	echo -e "\tNUMBER：函数序列的出现次数，配合-q选项设定故障序列出现NUMBER次后触发故障注入"
    exit 1
}

#1解析命令，确定功能
while getopts 't:b:f:i:r:p:v:e:d:y:s:l:c:x:q:k:' OPT; do
    case $OPT in
        t)
            FUN_TYPE="$OPTARG";; # k-kernel u-user 
        b)
            BIN_PATH="$OPTARG";; # bin path
        f)
            FUN_NAME="$OPTARG";; # function name or line of statement
        i)
            INJ_TYPE="$OPTARG";; # r-return p-paremeter s-statement
        r)
            RET_VAL="$OPTARG";; # return value
        p)
            PAR_NAME="$OPTARG";; # parameter name
        v)
            PAR_VAL="$OPTARG";; # parameter value
        e)
            CON_TYPE="$OPTARG";; # constraint type: k-kernel u-user 
        d)
            DLY_HEAD="$OPTARG";; # delay point - head
        y)
            DLY_TAIL="$OPTARG";; # delay point - tail
        s)
            DLY_SEC="$OPTARG";; # delay second
        l)
            TIM_LONG="$OPTARG";; # fault inject time span
        c)
            EXE_NAME="$OPTARG";; # target process name
        x)
            EXE_PID="$OPTARG";; # target process pid
        q)
            FUN_SEQ="$OPTARG";; # function name sequence
        k)
            SEQ_COUNT="$OPTARG";; # function name sequence count
        ?)
            usage
    esac
done

echo -e  -------参数解析-------
echo -e  处理完参数后的 OPTIND：$OPTIND
echo -e  移除已处理参数个数：$((OPTIND-1))
shift $(($OPTIND - 1))
echo -e  参数索引位置：$OPTIND
echo -e  准备处理余下的参数：
echo -e  "Other Params: $@"
echo -e  内核态/用户态：$FUN_TYPE
echo -e  二进制可执行文件路径：$BIN_PATH
echo -e  函数名称/语句位置：$FUN_NAME
echo -e  故障注入类型：$INJ_TYPE
echo -e  返回值：$RET_VAL
echo -e  参数名称：$PAR_NAME
echo -e  参数值：$PAR_VAL
echo -e  位置区间限定类型：$CON_TYPE
echo -e  位置区间限定开始位置：$DLY_HEAD
echo -e  位置区间限定结束位置：$DLY_TAIL
echo -e  延迟计时时间（s）：$DLY_SEC
echo -e  故障注入持续时间长度（s）：$TIM_LONG
echo -e  限定进程名：$EXE_NAME
echo -e  限定PID：$EXE_PID
echo -e  限定函数序列：$FUN_SEQ
echo -e  限定函数序列出现次数：$SEQ_COUNT

#2生成故障注入脚本
echo -e  -------生成故障注入脚本-------
time=$(date "+%Y%m%d%H%M%S") #获取当前时间
stp_file=$time".stp"
echo -e  creating SystemTap script: $stp_file
#时间约束
echo -e  "global fiFlag = 1" >> $stp_file # 0-关 1——开
if [ ! -n "$DLY_HEAD" -a ! -n "$DLY_TAIL" -a ! -n "$DLY_SEC" -a -n "$TIM_LONG" ]
then # test: bash fit.sh -t k -f sys_write -i r -r -22 -c test -l 5
	echo -e  "probe timer.sec($TIM_LONG)" >> $stp_file
	echo -e  "{" >> $stp_file
	echo -e  "\texit();" >> $stp_file
	echo -e  "}" >> $stp_file
elif [ ! -n "$DLY_HEAD" -a ! -n "$DLY_TAIL" -a -n "$DLY_SEC" -a -n "$TIM_LONG" ]
then # test: bash fit.sh -t k -f sys_write -i r -r -22 -c test -s 5 -l 10
	echo -e  "probe begin { fiFlag = 0; }" >> $stp_file
	echo -e  "probe timer.sec($DLY_SEC)" >> $stp_file
	echo -e  "{" >> $stp_file
	echo -e  "\tfiFlag = 1;" >> $stp_file
	echo -e  "}" >> $stp_file
	echo -e  "" >> $stp_file
	declare -i total=$(($DLY_SEC+$TIM_LONG))
	echo -e  "probe timer.sec($total)" >> $stp_file
	echo -e  "{" >> $stp_file
	echo -e  "\texit();" >> $stp_file
	echo -e  "}" >> $stp_file
	echo -e  "" >> $stp_file
elif [ -n "$DLY_HEAD" -a -n "$DLY_TAIL" -a ! -n "$TIM_LONG" -a "$FUN_TYPE" = "k" -a "$CON_TYPE" = "k" ]
then
	echo -e  "probe begin { fiFlag = 0; }" >> $stp_file
	echo -e  "probe kernel.function(\"$DLY_HEAD\").call" >> $stp_file
	echo -e  "{" >> $stp_file
	echo -e  "\tif(fiFlag == 0)" >> $stp_file
	echo -e  "\t\tfiFlag = 1;" >> $stp_file
	echo -e  "}" >> $stp_file
	echo -e  "" >> $stp_file
	echo -e  "probe kernel.function(\"$DLY_TAIL\").call" >> $stp_file
	echo -e  "{" >> $stp_file
	echo -e  "\tif(fiFlag == 1)" >> $stp_file
	echo -e  "\t\tfiFlag = 0;" >> $stp_file
	echo -e  "}" >> $stp_file
elif [ -n "$DLY_HEAD" -a -n "$DLY_TAIL" -a ! -n "$TIM_LONG" -a "$FUN_TYPE" = "k" -a "$CON_TYPE" = "u" -a -n "$BIN_PATH" ]
then # test: bash fit.sh -t k -f sys_write -i r -r -22 -e u -b ./test -c test -d fun1 -y fun4
	echo -e  "probe begin { fiFlag = 0; }" >> $stp_file
	echo -e  "probe process(\"$BIN_PATH\").function(\"$DLY_HEAD\").call" >> $stp_file
	echo -e  "{" >> $stp_file
	echo -e  "\tif(fiFlag == 0)" >> $stp_file
	echo -e  "\t\tfiFlag = 1;" >> $stp_file
	echo -e  "}" >> $stp_file
	echo -e  "" >> $stp_file
	echo -e  "probe process(\"$BIN_PATH\").function(\"$DLY_TAIL\").call" >> $stp_file
	echo -e  "{" >> $stp_file
	echo -e  "\tif(fiFlag == 1)" >> $stp_file
	echo -e  "\t\tfiFlag = 0;" >> $stp_file
	echo -e  "}" >> $stp_file
elif [ -n "$DLY_HEAD" -a -n "$DLY_TAIL" -a ! -n "$TIM_LONG" -a "$FUN_TYPE" = "u" -a -n "$BIN_PATH" -a "$CON_TYPE" = "u" ]
then # test: bash fit.sh -t u -b ./test -f fun3 -i r -r -10 -d fun1 -y fun4
	echo -e  "probe begin { fiFlag = 0; }" >> $stp_file
	echo -e  "probe process(\"$BIN_PATH\").function(\"$DLY_HEAD\").call" >> $stp_file
	echo -e  "{" >> $stp_file
	echo -e  "\tif(fiFlag == 0)" >> $stp_file
	echo -e  "\t\tfiFlag = 1;" >> $stp_file
	echo -e  "}" >> $stp_file
	echo -e  "" >> $stp_file
	echo -e  "probe process(\"$BIN_PATH\").function(\"$DLY_TAIL\").call" >> $stp_file
	echo -e  "{" >> $stp_file
	echo -e  "\tif(fiFlag == 1)" >> $stp_file
	echo -e  "\t\tfiFlag = 0;" >> $stp_file
	echo -e  "}" >> $stp_file
elif [ -n "$FUN_SEQ" -a -n "$SEQ_COUNT" -a ! -n "$BIN_PATH" ]
then # test: bash fit.sh -t k -f sys_write -i r -r -22 -q sys_write,sys_read,sys_open -k 3 -c test
	echo -e  "global seqCount = 0" >> $stp_file
	echo -e  "global fiCount = 0" >> $stp_file
	echo -e  "probe begin { fiFlag = 0; }" >> $stp_file
	OLD_IFS="$IFS"
	IFS=","
	arr=($FUN_SEQ)
	declare -i i=0
	for s in ${arr[@]}
	do
		echo -e  "probe kernel.function(\"$s\").call" >> $stp_file
		echo -e  "{" >> $stp_file
		if [ ${#arr[@]} = $((i+1)) ]
		then
			echo -e  "\tif(seqCount == $i)" >> $stp_file
			echo -e  "\t{" >> $stp_file
			echo -e  "\t\tseqCount = 0;" >> $stp_file
			echo -e  "\t\tfiCount = fiCount + 1;" >> $stp_file
			echo -e  "\t\tif(fiCount >= $SEQ_COUNT)" >> $stp_file
			echo -e  "\t\t{" >> $stp_file
			echo -e  "\t\t\tfiFlag = 1;" >> $stp_file
			echo -e  "\t\t\tfiCount = 0;" >> $stp_file
			echo -e  "\t\t}" >> $stp_file
			echo -e  "\t}" >> $stp_file
		else
			j=$((i+1))
			echo -e  "\tif(seqCount == $i) seqCount = $j;" >> $stp_file
		fi
		echo -e  "}" >> $stp_file
		echo -e  "" >> $stp_file
		i=i+1
	done
	IFS="$OLD_IFS"
elif [ -n "$FUN_SEQ" -a -n "$SEQ_COUNT" -a -n "$BIN_PATH" ]
then # test: bash fit.sh -t u -b ./test -f fun3 -i r -r -10 -q fun1,fun2,fun3,fun4 -k 3
	echo -e  "global seqCount = 0" >> $stp_file
	echo -e  "global fiCount = 0" >> $stp_file
	echo -e  "probe begin { fiFlag = 0; }" >> $stp_file
	OLD_IFS="$IFS"
	IFS=","
	arr=($FUN_SEQ)
	declare -i i=0
	for s in ${arr[@]}
	do
		echo -e  "probe process(\"$BIN_PATH\").function(\"$s\").call" >> $stp_file
		echo -e  "{" >> $stp_file
		if [ ${#arr[@]} = $((i+1)) ]
		then
			echo -e  "\tif(seqCount == $i)" >> $stp_file
			echo -e  "\t{" >> $stp_file
			echo -e  "\t\tseqCount = 0;" >> $stp_file
			echo -e  "\t\tfiCount = fiCount + 1;" >> $stp_file
			echo -e  "\t\tif(fiCount >= $SEQ_COUNT)" >> $stp_file
			echo -e  "\t\t{" >> $stp_file
			echo -e  "\t\t\tfiFlag = 1;" >> $stp_file
			echo -e  "\t\t\tfiCount = 0;" >> $stp_file
			echo -e  "\t\t}" >> $stp_file
			echo -e  "\t}" >> $stp_file
		else
			j=$((i+1))
			echo -e  "\tif(seqCount == $i) seqCount = $j;" >> $stp_file
		fi
		echo -e  "}" >> $stp_file
		echo -e  "" >> $stp_file
		i=i+1
	done
	IFS="$OLD_IFS"
fi
if [ -n "$FUN_TYPE" ]
then
	if [ "$FUN_TYPE" = "k" ]
	then
		#如果没有限定到特定的进程名或PID，则直接终止故障注入
		if [ ! -n "$EXE_NAME" -a ! -n "$EXE_PID" ]
		then
			echo -e  危险操作：对系统调用注入故障未限定到特定的进程名或PID，终止故障注入
			exit 1
		fi
		if [ -n "$FUN_NAME" -a "$INJ_TYPE" = "r" -a -n "$RET_VAL" ]
		then # test: bash fit.sh -t k -f sys_write -i r -r -22 -c test
			echo -e  probe kernel.function"(\"$FUN_NAME\").return" >> $stp_file
			echo -e  "{" >> $stp_file
			if [ -n "$EXE_PID" ]
			then
				echo -e  "\tif(pid() == $EXE_PID && fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$return = $RET_VAL;" >> $stp_file
			elif [ -n "$EXE_NAME" ]
			then
				echo -e  "\tif(execname() == \"$EXE_NAME\" && fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$return = $RET_VAL;" >> $stp_file
			else
				echo -e  "\tif( fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$return = $RET_VAL;" >> $stp_file
			fi
			echo -e  "}" >> $stp_file
		elif [ -n "$FUN_NAME" -a "$INJ_TYPE" = "p" -a -n "$PAR_NAME" -a -n "$PAR_VAL" ]
		then # test: bash fit.sh -t k -f sys_write -i p -p fd -v 222 -c test
			echo -e  probe kernel.function"(\"$FUN_NAME\").call" >> $stp_file
			echo -e  "{" >> $stp_file
			if [ -n "$EXE_PID" ]
			then
				echo -e  "\tif(pid() == $EXE_PID && fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$$PAR_NAME = $PAR_VAL;" >> $stp_file
			elif [ -n "$EXE_NAME" ]
			then
				echo -e  "\tif(execname() == \"$EXE_NAME\" && fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$$PAR_NAME = $PAR_VAL;" >> $stp_file
			else
				echo -e  "\tif( fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$$PAR_NAME = $PAR_VAL;" >> $stp_file
			fi
			echo -e  "}" >> $stp_file
		elif [ -n "$FUN_NAME" -a "$INJ_TYPE" = "s" -a -n "$PAR_NAME" -a -n "$PAR_VAL" ]
		then # test: bash fit.sh -t k -f sys_write@fs/read_write.c+4 -i s -p count -v 2 -c test
			echo -e  probe kernel.statement"(\"$FUN_NAME\")" >> $stp_file
			echo -e  "{" >> $stp_file
			if [ -n "$EXE_PID" ]
			then
				echo -e  "\tif(pid() == $EXE_PID && fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$$PAR_NAME = $PAR_VAL;" >> $stp_file
			elif [ -n "$EXE_NAME" ]
			then
				echo -e  "\tif(execname() == \"$EXE_NAME\" && fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$$PAR_NAME = $PAR_VAL;" >> $stp_file
			else
				echo -e  "\tif( fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$$PAR_NAME = $PAR_VAL;" >> $stp_file
			fi
			echo -e  "}" >> $stp_file
		else
			usage
		fi
	elif [ "$FUN_TYPE" = "u" ]
	then
		if [  -n "$BIN_PATH" -a -n "$FUN_NAME" -a "$INJ_TYPE" = "r" -a -n "$RET_VAL" ]
		then # test: bash fit.sh -t u -b ./test -f fun1 -i r -r -10 -c test
			echo -e  "probe process(\"$BIN_PATH\").function(\"$FUN_NAME\").return" >> $stp_file
			echo -e  "{" >> $stp_file
			if [ -n "$EXE_PID" ]
			then
				echo -e  "\tif(pid() == $EXE_PID && fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$return = $RET_VAL;" >> $stp_file
			elif [ -n "$EXE_NAME" ]
			then
				echo -e  "\tif(execname() == \"$EXE_NAME\" && fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$return = $RET_VAL;" >> $stp_file
			else
				echo -e  "\tif( fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$return = $RET_VAL;" >> $stp_file
			fi
			echo -e  "}" >> $stp_file
		elif [ -n "$BIN_PATH" -a -n "$FUN_NAME" -a "$INJ_TYPE" = "p" -a -n "$PAR_NAME" -a -n "$PAR_VAL" ]
		then # test: bash fit.sh -t u -b ./test -f fun1 -i p -p p1 -v 222
			echo -e  "probe process(\"$BIN_PATH\").function(\"$FUN_NAME\").call" >> $stp_file
			echo -e  "{" >> $stp_file
			if [ -n "$EXE_PID" ]
			then
				echo -e  "\tif(pid() == $EXE_PID && fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$$PAR_NAME = $PAR_VAL;" >> $stp_file
			elif [ -n "$EXE_NAME" ]
			then
				echo -e  "\tif(execname() == \"$EXE_NAME\" && fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$$PAR_NAME = $PAR_VAL;" >> $stp_file
			else
				echo -e  "\tif( fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$$PAR_NAME = $PAR_VAL;" >> $stp_file
			fi
			echo -e  "}" >> $stp_file
		elif [ -n "$BIN_PATH" -a -n "$FUN_NAME" -a "$INJ_TYPE" = "s" -a -n "$PAR_NAME" -a -n "$PAR_VAL" ]
		then # test: bash fit.sh -t u -b ./test -f fun1@test.c+3 -i s -p p1 -v 100
			echo -e  "probe process(\"$BIN_PATH\").statement(\"$FUN_NAME\")" >> $stp_file
			echo -e  "{" >> $stp_file
			if [ -n "$EXE_PID" ]
			then
				echo -e  "\tif(pid() == $EXE_PID && fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$$PAR_NAME = $PAR_VAL;" >> $stp_file
			elif [ -n "$EXE_NAME" ]
			then
				echo -e  "\tif(execname() == \"$EXE_NAME\" && fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$$PAR_NAME = $PAR_VAL;" >> $stp_file
			else
				echo -e  "\tif( fiFlag == 1)" >> $stp_file
				echo -e  "\t\t\$$PAR_NAME = $PAR_VAL;" >> $stp_file
			fi
			echo -e  "}" >> $stp_file
		fi
	else
		usage
	fi
else
	usage
fi
echo -e  created SystemTap script: $stp_file

#3执行故障注入脚本
echo -e  -------执行故障注入脚本-------
`stap -vg $stp_file`
echo -e  -------故障注入脚本执行完毕-------
