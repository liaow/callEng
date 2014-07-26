#!/bin/bash
#####################################################
#             引擎调用通用shell                     #
#              liaow@gmail.com                      #
#                                                   #
#  更新历史                                         #
#  2014-07-26  创建脚本                             #
#  2014-07-27  支撑不指定地市或者情况从数据库取     #
#                                                   #
#  待演进功能                                       #
#  1、地市和业务有效性校验                          #
#  2、指定节点单独运行支撑                          #
#  3、检测RWD_HOME是否定义，否则find来定义          #
#####################################################

#自适应定义SHELL_HOME目录
SHELL_HOME=$(cd `dirname $0`; pwd)
LOG_PATH=$SHELL_HOME/log

#没有指定地州或者业务时是否使用数据库自动读取
#使用Wmsys.Wm_Concat函数需要oracle10.2版本以上
DB_ON=Y
CONNSTR="USER/PASSWD@TNS_NAME"

startTime=`date +%s`
startTimeStr=`date +"%Y%m%d%H%M%S"`

#shell call日志
if [ ! -d "$LOG_PATH" ]; then
    mkdir $LOG_PATH
fi

callLogFile=${LOG_PATH}/call_${SETT_MONTH}_${startTimeStr}.log
if [ -f $callLogFile ]; then
        rm $callLogFile
fi

echo `date +"%Y-%m-%d %H:%M:%S"`"###################################################################" >> $callLogFile
echo `date +"%Y-%m-%d %H:%M:%S"`"#  DO PLEASE CHECK ENV HAS A RWD_HOME , AND MAKE IT TAKE EFFECT!  #" >> $callLogFile
echo `date +"%Y-%m-%d %H:%M:%S"`"#       请检查环境变量RWD_HOME是否配置，否则配置并使其生效！      #" >> $callLogFile
echo `date +"%Y-%m-%d %H:%M:%S"`"###################################################################" >> $callLogFile

usage ()
{
        echo "Usage : Script -[option]"
        echo "  p,  program_name,    必选,  程序名 CalApp 或者 TransTL"
        echo "  e,  eparchy_code,    必选,  需要处理的地州编码(4位)"
        echo "  c,  sett_month,      必选,  需要处理的月份[-1:上月;0:本月;其他(yyyymm):指定账期]"
        echo "  r,  rule_type_code,  必选,  类型,如4100"
        echo "  i,  ini_file,        可选,  指定配置文件(cfg.ini)"
        echo "  t,  node_id,         可选,  指定节点"
        echo "  m,  max_active,      可选,  最大并发数"
        echo "  o,  other_params,    可选,  其他引擎可支持参数"
        exit
}

#参数解析
while getopts ":p:e:c:r:i:t:m:o:" opt
do
        case $opt in
        p)
                PROGRAM_NAME="$OPTARG"
                echo `date +"%Y-%m-%d %H:%M:%S"`" PROGRAM_NAME=" "$OPTARG" >> $callLogFile
                ;;
        e)
                EPARCHY_CODE="$OPTARG"
                echo `date +"%Y-%m-%d %H:%M:%S"`" EPARCHY_CODE=" "$OPTARG" >> $callLogFile
                ;;
        c)
                SETT_MONTH="$OPTARG"
                echo `date +"%Y-%m-%d %H:%M:%S"`" SETT_MONTH=" "$OPTARG" >> $callLogFile
                ;;
        r)
                RULE_TYPE_CODE="$OPTARG"
                echo `date +"%Y-%m-%d %H:%M:%S"`" RULE_TYPE_CODE=" "$OPTARG" >> $callLogFile
                ;;
        i)
                CONFIG_FILE="$OPTARG"
                echo `date +"%Y-%m-%d %H:%M:%S"`" CONFIG_FILE=" "$OPTARG" >> $callLogFile
                ;;
        t)
                NODE_ID="$OPTARG"
                echo `date +"%Y-%m-%d %H:%M:%S"`" NODE_ID=" "$OPTARG" >> $callLogFile
                ;;
        m)
                MAX_ACTIVE="$OPTARG"
                echo `date +"%Y-%m-%d %H:%M:%S"`" MAX_ACTIVE=" "$OPTARG" >> $callLogFile
                ;;
        o)
                OTHER_PARAMS="$OPTARG"
                echo `date +"%Y-%m-%d %H:%M:%S"`" OTHER_PARAMS=" "$OPTARG" >> $callLogFile
                ;;
        ?) usage;;
        esac
done

#检查参数必填项
if [ x"$PROGRAM_NAME" = x ] ; then
        usage
fi
if [ x"$EPARCHY_CODE" = x ] ; then
        usage
fi
if [ x"$SETT_MONTH" = x ] ; then
        usage
fi
if [ x"$RULE_TYPE_CODE" = x ] ; then
        usage
fi

#设置默认并发
if [ x"$MAX_ACTIVE" = x ] ; then
        MAX_ACTIVE=1
fi

#处理账期
if [ $SETT_MONTH -eq -1 ]; then
	year=`date +"%Y"`
	month=`date +"%m" `
	let "lastMonth=month-1"
	if [ $lastMonth -eq 0 ]; then
	  let "year=year-1"
	  lastMonth=12
	elif [ $lastMonth -lt 10 ]; then
	  lastMonth="0"$lastMonth
	fi
	SETT_MONTH=$year$lastMonth
fi
if [ $SETT_MONTH -eq 0 ]; then
	SETT_MONTH=`date +"%Y%m"`
fi

#多参数输入处理
#从数据库读业务编码
if [ "$DB_ON" = "Y" ] ; then
    TMP_RULE_TYPE_CODE=`sqlplus -silent $CONNSTR <<EOF  
    SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF  
    Select Wmsys.Wm_Concat(Data_Id) ruleType From Rwd_Core_Static a Where a.Type_Id = 'RWD_RULE_TYPE_CODE';
    EXIT;  
EOF`
fi
echo `date +"%Y-%m-%d %H:%M:%S"`" RULE_TYPE_CODE equals ${RULE_TYPE_CODE} ,use database =${DB_ON} , TMP_RULE_TYPE_CODE : "$TMP_RULE_TYPE_CODE >>$callLogFile

if [ "$RULE_TYPE_CODE" -eq 0 ] ; then
    if [ -z "$TMP_RULE_TYPE_CODE" ]; then
        RULE_TYPE_CODE="4000,4110,4120,4130,4140,4150,4250"
    else
        RULE_TYPE_CODE=$TMP_RULE_TYPE_CODE
    fi
fi
echo `date +"%Y-%m-%d %H:%M:%S"`" RULE_TYPE_CODE equals ${RULE_TYPE_CODE} ,use database =${DB_ON} , current RULE_TYPE_CODE : "$RULE_TYPE_CODE >>$callLogFile

#从数据库读地州编码
if [ "$DB_ON" = "Y" ] ; then
    TMP_EPARCHY_CODE=`sqlplus -silent $CONNSTR <<EOF  
    SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF  
    Select Wmsys.Wm_Concat(Area_Code) areaCode From Rwd_Core_Area a Where a.Area_Level = 20;  
    EXIT;  
EOF`
fi
echo `date +"%Y-%m-%d %H:%M:%S"`" EPARCHY_CODE equals ${EPARCHY_CODE} ,use database =${DB_ON} , TMP_EPARCHY_CODE : "$TMP_EPARCHY_CODE >>$callLogFile

if [ "$EPARCHY_CODE" -eq 0 ]; then
    if [ -z "$TMP_EPARCHY_CODE" ]; then
        EPARCHY_CODE="0770,0771,0772,0773,0774,0775,0776,0777,0778,0779,0780,0781,0782,0783"
    else
        EPARCHY_CODE=$TMP_EPARCHY_CODE
    fi
fi
echo `date +"%Y-%m-%d %H:%M:%S"`" EPARCHY_CODE equals ${EPARCHY_CODE} ,use database =${DB_ON} , current EPARCHY_CODE : "$EPARCHY_CODE >>$callLogFile

#有节点时需要拼-t
if [ x"${NODE_ID}" = x ]; then
        NODE_PARAM=""
else
        NODE_PARAM="-t"${NODE_ID}
        echo "node param is "${NODE_PARAM}
fi

#没有指定config取默认配置
if [ x"${CONFIG_FILE}" = x ]; then
        CONFIG_FILE="${RWD_HOME}/config/cal_cfg.ini"
        echo `date +"%Y-%m-%d %H:%M:%S"`" CONFIG_FILE seems null ,use default config file : "$CONFIG_FILE >>$callLogFile
fi

echo `date +"%Y-%m-%d %H:%M:%S"`" SETT_MONTH="$SETT_MONTH";EPARCHY_CODE="$EPARCHY_CODE";RULE_TYPE_CODE="$RULE_TYPE_CODE";NODE_PARAM="$NODE_PARAM";CONFIG_FILE="$CONFIG_FILE >>$callLogFile

echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------------------------------------------------------" >>$callLogFile
echo `date +"%Y-%m-%d %H:%M:%S"`"------------------------------------all biz begin----------------startTime="$startTime >>$callLogFile
echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------------------------------------------------------" >>$callLogFile

arrEparchyCodes=(${EPARCHY_CODE//,/ })
arrRuleTypeCodes=(${RULE_TYPE_CODE//,/ })

#shell 程序日志
programLogFile=${LOG_PATH}/${PROGRAM_NAME}_${SETT_MONTH}_${startTimeStr}.log
if [ -f $programLogFile ]; then
        rm $programLogFile
fi

#切换到引擎目录
cd $RWD_HOME/bin

#开始处理
for ruleTypeCode in ${arrRuleTypeCodes[@]}; do
        for eparchyCode in ${arrEparchyCodes[@]}; do
                AMOUNT=` ps -ef |grep "$PROGRAM_NAME" | grep -v $0 | grep -v grep |sort -u |wc -l `;
                AMOUNT2=` ps -ef |grep "$PROGRAM_NAME" | grep -v $0 | grep "$eparchyCode" |grep -v grep |sort -u |wc -l `;
                #echo "ps -ef,AMOUNT="${AMOUNT}",AMOUNT2="${AMOUNT2}",MAX_ACTIVE="${MAX_ACTIVE}
                while [ "$AMOUNT" -ge ${MAX_ACTIVE} ] || [ "$AMOUNT2" -eq 1 ]; do
                    #echo "sleep ..."
                    sleep 10
                    AMOUNT=` ps -ef |grep "$PROGRAM_NAME" | grep -v $0 | grep -v grep |sort -u |wc -l `;
                    AMOUNT2=` ps -ef |grep "$PROGRAM_NAME" | grep -v $0 | grep "$eparchyCode" |grep -v grep |sort -u |wc -l `;
                    #echo "ps -ef ,AMOUNT="${AMOUNT}",AMOUNT2="${AMOUNT2}",MAX_ACTIVE="${MAX_ACTIVE}
                done
                sleep 10
                echo " begin execute $PROGRAM_NAME,param[sett_month|eparchy_code|rule_type_code|node_id|max_active|config_file|other_params]" >> $callLogFile
                echo "                                 ["$SETT_MONTH"|"$eparchyCode"|"$ruleTypeCode"|"$NODE_ID"|"$MAX_ACTIVE"|"$CONFIG_FILE"|"$OTHER_PARAMS"]" >> callLogFile
                #程序调用开始
                echo " ./"$PROGRAM_NAME" -i"${CONFIG_FILE}" -c"${SETT_MONTH}" -e"${eparchyCode}" -r"${ruleTypeCode}" "${NODE_PARAM}" -"${OTHER_PARAMS} >> $callLogFile
                ./$PROGRAM_NAME -i${CONFIG_FILE} -c${SETT_MONTH} -e${eparchyCode} -r${ruleTypeCode} ${NODE_PARAM} -${OTHER_PARAMS} >> $programLogFile
        done
done

AMOUNT=` ps -ef |grep "$PROGRAM_NAME" | grep -v $0 |grep -v grep |sort -u |wc -l `;
while [ "$AMOUNT" -ge 1 ]; do
        sleep 10
        AMOUNT=` ps -ef |grep "$PROGRAM_NAME" | grep -v $0 |grep -v grep |sort -u |wc -l `;
done

endTime=`date +%s`
allDurationTime=$(($endTime-$startTime))

echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------------------------------------------------------" >>$callLogFile
echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------all biz end---------------------endTime="$endTime >>$callLogFile
echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------all biz deal completed! cost "$allDurationTime" secs" >>$callLogFile
echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------------------------------------------------------" >>$callLogFile
echo "ok!"
exit 0;
