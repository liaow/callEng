callEng
=======

引擎调用通用shell

一、使用帮助                             
  callEng.sh -h

 
二、执行日志说明                             
  执行时间 time1 如：20130821150733                             
  主日志：./log/call_${time1}.log                           
  详细日志：./log/${PROGRAM_NAME}_${eparchyCode}_${ruleTypeCode}_${startTimeStr}.log

三、其他说明                             
  没有指定地州或者业务时是否使用数据库自动读取（使用Wmsys.Wm_Concat函数需要oracle10.2版本以上）                             
  需要修改脚本：                             
  DB_ON=Y                             
  CONNSTR="USER/PASSWD@TNS_NAME"                   
                                                   
四、更新历史                                         
  2014-07-26  创建脚本                             
  2014-07-27  支撑不指定地市或者情况从数据库取
  2014-07-28  并发改用统计子脚本(-p程序本身并发)，修改多值传递分割方式(半角英文分号)
                                                   
五、待演进功能                                       
  1、地市和业务有效性校验                          
  2、指定节点单独运行支撑                          
  3、检测RWD_HOME是否定义，否则find来定义          
