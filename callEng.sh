#!/bin/bash
rulehome=/data11/airwdeng/reward_run
bindir=$rulehome/svr
logDir=$rulehome/log/shelllog

if [ $# -lt 3 -a $# -lt 4 -a  $# -lt 5 -a $# -lt 6 ]; then
        echo "input param err,please type cmd like (calMaxCnt,calMode,settMonth,eparchyCode,ruleTypeCode,nodeSeq)"
        exit -1;
fi

maxCnt=$1

echo "input param maxCnt="$maxCnt

if [ "$maxCnt" -ne 1 ] && [ "$maxCnt" -ne 2 ] && [ "$maxCnt" -ne 3 ]; then
	echo "maxCnt value need equals 1 or 2 or 3"
	exit -1;
fi

calMode=$2

if [ "$calMode" -ne 1 ] && [ "$calMode" -ne 2 ] && [ "$calMode" -ne 3 ] && [ "$calMode" -ne 4 ]; then
	echo "calMode value need equals 1 or 2 or 3 or 4 means null or m or y or ym"
	exit -1;
fi

echo "input param calMode="$calMode

settMonth=$3
echo "input param settMonth="$settMonth

if [ $settMonth -eq -1 ]; then
	year=`date +"%Y"`
	month=`date +"%m" `
	let "lastMonth=month-1"
	if [ $lastMonth -eq 0 ]; then
	  let "year=year-1"
	  lastMonth=12
	elif [ $lastMonth -lt 10 ]; then
	  lastMonth="0"$lastMonth
	fi
	settMonth=$year$lastMonth
fi

if [ $settMonth -eq 0 ]; then
	settMonth=`date +"%Y%m"`
fi

echo "input param settMonth trans result="$settMonth

if [ ! -d "$logDir/$settMonth" ]; then
	mkdir "$logDir/$settMonth"
fi
startTime=`date +%s`
startTimeStr=`date +"%Y%m%d%H%M%S"`
tmpLogDir=$logDir/$settMonth/$startTimeStr
if [ -d "$tmpLogDir" ]; then
        rm -r "$tmpLogDir"
fi
mkdir "$tmpLogDir"
ruleCalLogFile=${tmpLogDir}/ruleCal_${settMonth}_${startTimeStr}.log
if [ -f $ruleCalLogFile ]; then
        rm $ruleCalLogFile
fi

echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------------------------------------------------------"
echo `date +"%Y-%m-%d %H:%M:%S"`"------------------------------------all biz begin----------------startTime="$startTime
echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------------------------------------------------------"

echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------------------------------------------------------" >>$ruleCalLogFile
echo `date +"%Y-%m-%d %H:%M:%S"`"------------------------------------all biz begin----------------startTime="$startTime >>$ruleCalLogFile
echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------------------------------------------------------" >>$ruleCalLogFile

if [ $# -eq 4 ]; then
        if [ ` expr substr "$4" 1 1 ` -eq 0 ]; then
                eparchyCodes=$4
        else
                ruleTypeCodes=$4
        fi
fi

if [ $# -eq 5 ]; then
        if [ ` expr substr "$4" 1 1 ` -eq 0 ]; then
                eparchyCodes=$4
                ruleTypeCodes=$5
        else
                ruleTypeCodes=$4
                nodeSeq=$5
        fi
        
fi

if [ $# -eq 6 ]; then
        eparchyCodes=$4
        ruleTypeCodes=$5
        nodeSeq=$6
fi

eparchyCodes=`echo $eparchyCodes | sed 's/:/,/g'`
ruleTypeCodes=`echo $ruleTypeCodes | sed 's/:/,/g'`
nodeSeq=`echo $nodeSeq | sed 's/:/,/g'`
echo "input param eparchyCodes="$eparchyCodes
echo "input param ruleTypeCodes="$ruleTypeCodes
echo "input param nodeSeq="$nodeSeq

if [ ` expr length "$eparchyCodes" ` -eq 0 ]; then
        eparchyCodes="0570,0571,0572,0573,0574,0575,0576,0577,0578,0579,0580"
fi

if [ ` expr length "$ruleTypeCodes" ` -eq 0 ]; then
        ruleTypeCodes="4000,4110,4120,4130,4140,4150,4230,4240,4250,4260,4270,4280,4290,4310,4330,4340"
fi

echo `date +"%Y-%m-%d %H:%M:%S"`"------settMonth="$settMonth"----eparchyCodes="$eparchyCodes"-----ruleTypeCodes="$ruleTypeCodes"-----nodeSeq="$nodeSeq
echo `date +"%Y-%m-%d %H:%M:%S"`"------settMonth="$settMonth"----eparchyCodes="$eparchyCodes"-----ruleTypeCodes="$ruleTypeCodes"-----nodeSeq="$nodeSeq >>$ruleCalLogFile

if [ ` expr index "$eparchyCodes" "," ` -gt 0 ]; then
        eparchyCodesReplace=`echo $eparchyCodes | sed 's/,/ /g'`
        eval set -A arrEparchyCodes $eparchyCodesReplace
else
        eval set -A arrEparchyCodes $eparchyCodes
        maxCnt=1
fi

if [ ` expr index "$ruleTypeCodes" "," ` -gt 0 ]; then
        ruleTypeCodesReplace=`echo $ruleTypeCodes | sed 's/,/ /g'`
        eval set -A arrRuleTypeCodes $ruleTypeCodesReplace
else
        eval set -A arrRuleTypeCodes $ruleTypeCodes
fi

for ruleTypeCode in ${arrRuleTypeCodes[@]}; do
        for eparchyCode in ${arrEparchyCodes[@]}; do
                AMOUNT=` ps -ef |grep executeCalApp |grep -v grep |sort -u |wc -l `;
                AMOUNT2=` ps -ef |grep executeCalApp |grep "$eparchyCode" |grep -v grep |sort -u |wc -l `;
                while [ "$AMOUNT" -ge ${maxCnt} ] || [ "$AMOUNT2" -eq 1 ]; do
                        sleep 10
                        AMOUNT=` ps -ef |grep executeCalApp |grep -v grep |sort -u |wc -l `;
                        AMOUNT2=` ps -ef |grep executeCalApp |grep "$eparchyCode" |grep -v grep |sort -u |wc -l `;
                done
                sleep 10
                echo "begin execute CalApp,param[calMode|settMonth|eparchyCode|ruleTypeCode]=["$calMode"|"$settMonth"|"$eparchyCode"|"$ruleTypeCode"]"
                if [ "${nodeSeq}" -eq "" ]; then
                        sh ./executeCalApp.sh $startTimeStr $calMode $settMonth $eparchyCode $ruleTypeCode &
                else
                        sh ./executeCalApp.sh $startTimeStr $calMode $settMonth $eparchyCode $ruleTypeCode $nodeSeq &
                fi
        done
done

AMOUNT=` ps -ef |grep executeCalApp |grep -v grep |sort -u |wc -l `;
while [ "$AMOUNT" -ge 1 ]; do
        sleep 10
        AMOUNT=` ps -ef |grep executeCalApp |grep -v grep |sort -u |wc -l `;
done

endTime=`date +%s`
allDurationTime=$(($endTime-$startTime))

echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------------------------------------------------------"
echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------all biz end---------------------endTime="$endTime
echo `date +"%Y-%m-%d %H:%M:%S"`"---------------------------------------all biz deal completed! cost "$allDurationTime" secs"
echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------------------------------------------------------"

echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------------------------------------------------------" >>$ruleCalLogFile
echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------all biz end---------------------endTime="$endTime >>$ruleCalLogFile
echo `date +"%Y-%m-%d %H:%M:%S"`"---------------------------------------all biz deal completed! cost "$allDurationTime" secs" >>$ruleCalLogFile
echo `date +"%Y-%m-%d %H:%M:%S"`"-------------------------------------------------------------------------------------" >>$ruleCalLogFile
echo "ok!"
exit 0;
