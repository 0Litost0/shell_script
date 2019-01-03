#!/bin/sh
# Brief:
# 	该脚本，将输入的文件或是目录(递归)中的文件编码格式，自动转换为目标格式，添加-r选项后，则直接替换原有文件
# Notice:
#	1.检测到ISO-8859前缀的，但是iconv没有完全匹配的编码类型的话（如：ISO_8859-1，ISO_8859-2），则统一视为GBK
#	2.需要系统支持icionv，file等指令
#	3.-o,-r选项不能共存
#	4.经测试，当文件类型为GBK时，file指令不加参数的话，显示编码类型为ISO-8859；file指令加 -i 参数的话，显示编码类型为ISO-8859-1
#Param
#	-o DstPath 目的路径
#	-t DstEncode 目的编码类型（具体支持的编码类型，可通过 iconv -l 查看）
#	-r 直接覆盖源文件
#	[SrcPath] 原路径(文件、目录)
#Example
#	1.覆盖源文件
#	ConvertEncode.sh -r -t GBK SrcPath  
#	2.转码后，并保存在指定目录
#	ConvertEncode.sh -t GBK SrcPath  -o DstPath 
# History:
# 2018/12/29	Litost_Cheng	First release

function pack_example(){
cat<<EOT
---------------------------------------------------------------------------------------------
# Brief:
# 	该脚本，将输入的文件或是目录(递归)中的文件编码格式，自动转换为目标格式，添加-r选项后，则直接替换原有文件
# Notice:
#	1.检测到ISO-8859前缀的，但是iconv没有完全匹配的编码类型的话（如：ISO_8859-1，ISO_8859-2），则统一视为GBK
#	2.需要系统支持icionv，file等指令
#	3.-o,-r选项不能共存
#	4.经测试，当文件类型为GBK时，file指令不加参数的话，显示编码类型为ISO-8859；file指令加 -i 参数的话，显示编码类型为ISO-8859-1
#Param
#	-o DstPath 目的路径
#	-t DstEncode 目的编码类型（具体支持的编码类型，可通过 iconv -l 查看）
#	-r 直接覆盖源文件
#	[SrcPath] 原路径(文件、目录)
#Example
#	1.覆盖源文件
#	ConvertEncode.sh -r -t GBK SrcPath  
#	2.转码后，并保存在指定目录
#	ConvertEncode.sh -t GBK SrcPath  -o DstPath 
# History:
# 2018/12/29	Litost_Cheng	First release
---------------------------------------------------------------------------------------------
EOT
exit ${1}
}



function Convert()
{
	#判断是文件
	if [ -f "${1}" -o -L "${1}" ];then
		FileEncodeType=""
		FileEncodeType=`file -i ${1} | awk -F "=" '{print toupper($2)}'`
		TempStr=`iconv -l | grep -i "^${FileEncodeType}//"`
		TempStr=${TempStr%//}
		
		#判断iconv是否支持源文件格式
		if [ "${TempStr}" == "" ];then
			#如果没有此种类型，但包含ISO_8859前缀，那么都默认为 GBK
			if [ "FileEncodeType" == "ISO_8859" ];then
				TempStr="GBK"				
			else	#如果不包含ISO_8859前缀，则不执行任何操作
				:
			fi
		fi
		
		#经测试，当文件类型为GBK时，file指令不加参数的话，显示编码类型为ISO-8859
		#file指令加 -i 参数的话，显示编码类型为ISO-8859-1
		if [ "${TempStr}" == "ISO-8859-1" ];then
			TempStr="GBK"
		fi
		
		if [ "${TempStr}" != "" ];then
			if [ "${FileEncodeType}" == "${DstEncode}" ];then
				printf "${1} 格式为 ${DstEncode} 无需转换\n" 
			else
				#覆盖源文件
				if [ "${RorO}" == "R" ];then
					#创建备份文件前，先确认备份文件是否存在，存在的话，需要给出提示信息
					if [ -f "${1}_bak" ];then
						echo "************文件 ${1}_bak已存在，将会覆盖************"
					fi
					#转码
					iconv -c -f ${TempStr} -t ${DstEncode} ${1} -o "${1}_bak"
					printf "iconv -c -f ${TempStr} -t ${DstEncode} ${1} -o ${1}_bak\n"
					#删除源文件
					rm -f ${1}
					#用备份文件替换原有文件
					mv "${1}_bak" ${1}
				#目的路径生成保存转码后的文件
				else
					iconv -c -f ${TempStr} -t ${DstEncode} ${1} -o "${DstPath}/${1}"
					printf "iconv -c -f ${TempStr} -t ${DstEncode} ${1} -o ${DstPath}/${1}\n"
				fi
			fi
				
		fi
	#判断是目录
	elif [  -d "${1}" ];then
		ListOfElement=`ls ${1}`
		for Element in ${ListOfElement}
		do
#			echo "尝试重定向 ${Element}"
			Convert ${1}/${Element}
		done
	
	else
		echo "[${1}] is not file or directory!"
	fi
}
ExecuteDitecrPath=""


SrcPath=""
DstPath=""
#当前、源、目的的绝对路径
CurAbsolutePath=""
SrcAbsolutePath=""
DstAbsolutePath=""
DstEncode=""
FileEncodeType=""
#用以判断是需要覆盖，还是在目的路径生成新文件
RorO=""
#获取当前绝对路径
CurAbsolutePath=`pwd`

TEMP=`getopt -o rt:o: -- "$@"`

if [ $? != 0 ] ; then echo -e "参数输入错误，示例: ${0} -m 重定向位置 待处理进程名" >&2 ; exit 1 ; fi


#set 会重新排列参数的顺序，也就是改变$1,$2...$n的值，这些值在getopt中重新排列过了
eval set -- "$TEMP"

while true ; do
	case "$1" in
			-o) 	# -O, -R不能共存
				DstPath=${2};
				if [ "${RorO}" == "" ];then
					RorO="O"
				else
					echo "-o, -r 不能共存"
					pack_example 1
					
				fi
				shift 2 ;;
			-r) 
				if [ "${RorO}" == "" ];then
					RorO="R"
				else
					echo "-o, -r 不能共存"
					pack_example 2
				fi
				shift  ;;			
			-t) DstEncode=${2}; shift 2 ;;
			--) shift ; break ;;
			*) echo "Internal error!" ; exit 1 ;;
	esac
done

SrcPath=${1}

if [ "${RorO}" == "" ];then
	echo "请用-o 指定目的路径，或用-r 指明覆盖当前文件"
	pack_example 3
fi

#判断iconv是否支持目的类型编码
if [ "${DstEncode}" == "" ];then
	echo "请输入目的编码"
	pack_example 3
fi

TempStr=`iconv -l | grep "^${DstEncode}//"`
TempStr=${TempStr%//}
if [ "${TempStr}" == "" ] ; then 
	echo -e "未检测到 ${DstEncode} 类型，将使用默认编码格式：GBK ";
	DstEncode="GBK"; 
fi

#倘若原路径为目录，则获取源绝对路径
if [ -d "${SrcPath}" ];then
	cd ${CurAbsolutePath}
	cd ${SrcPath}
	SrcAbsolutePath=`pwd`
	cd ${CurAbsolutePath}
fi


#如果指定了目录（-o），需要确保目的路径存在
if [ "${RorO}" == "O" -a "${DstPath}" != "" ];then
	cd ${CurAbsolutePath}
	mkdir -p ${DstPath}
	DstAbsolutePath=`pwd`
	
	#递归创建目的路径
	#如果指定了目的路径，则需要递归创建路径
	if [ -d "${SrcPath}" ];then
		find ${SrcPath} -type d -exec mkdir -p ${DstPath}/{} \;
	else
		echo "源目录不存在"
		pack_example 4
	fi

fi

cd ${CurAbsolutePath}
#echo "SrcPath is ${SrcPath}"
Convert ${SrcPath}
exit 0


