callEng
=======

引擎调用通用shell

一、使用帮助
callEng.sh -h
usage ()
{
        echo "Usage : Script -[option]"
        echo "  p,  program_name,    必选,  程序名 CalApp 或者 TransTL"
        echo "  e,  eparchy_code,    必选,  需要处理的地州编码(4位)[0表示所有地州,也可以传多个以半角逗号隔开],参考其他说明"
        echo "  c,  sett_month,      必选,  需要处理的月份[-1:上月;0:本月;其他(yyyymm):指定账期]"
        echo "  r,  rule_type_code,  必选,  类型,如4100[0表示所有业务,也可以传多个以半角逗号隔开],参考其他说明"
        echo "  i,  ini_file,        可选,  指定配置文件(cfg.ini)"
        echo "  t,  node_id,         可选,  指定节点"
        echo "  m,  max_active,      可选,  最大并发数"
        echo "  o,  other_params,    可选,  其他引擎可支持参数"
        exit
}
 
二、执行日志说明
	执行时间 time1 如：20130821150733
	主日志：./log/call_${SETT_MONTH}/${time1}.log
	详细日志：./log/${PROGRAM_NAME}_${SETT_MONTH}_${time1}.log

三、其他说明
没有指定地州或者业务时是否使用数据库自动读取（使用Wmsys.Wm_Concat函数需要oracle10.2版本以上）
需要修改脚本：
DB_ON=Y
CONNSTR="rwd_busi/airwddb+1@AIRWDDB_124_122"                   
                                                   
四、更新历史                                         
  2014-07-26  创建脚本                             
  2014-07-27  支撑不指定地市或者情况从数据库取     
                                                   
五、待演进功能                                       
  1、地市和业务有效性校验                          
  2、指定节点单独运行支撑                          
  3、检测RWD_HOME是否定义，否则find来定义          
