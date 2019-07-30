#!/bin/bash
project=$1
project_name=""
upgrade_pkg=${2:-''}
time_subfix=$(date +%Y%m%d%H%M%S)
#如果没有指定包名，则查找项目对应的最新的包
if [ x"$upgrade_pkg" == x"" ];then
    if [ x"$project" == x"q" ];then
	upgrade_pkg=$(find /data -maxdepth 1 -name qsb-\*|xargs ls -lt|head -1|awk '{ print $NF}')
	project_name="qsb"
    elif [ x"$project" == x"qb" ];then 
	upgrade_pkg=$(find /data -maxdepth 1 -name qsbBackstage-\*|xargs ls -lt|head -1|awk '{ print $NF}')
	project_name="qsbBackstage"
    else
	echo "脚本执行格式如下:./upgrade.sh q|qb [package]"
	echo "q代表qsb项目，qb代表qsbBackstage项目,package为升级包名,不指定,使用最新的上传的包,如果是qsb项目,则使用最近上传的qsb-0.0.1-SNAPSHOT*,如果是qsbBackstage项目,则使用qsbBackstage-0.0.1-*"
	exit 1
    fi
	
fi
#解压文件
mkdir ./temp_upgrade
rm ./temp_upgrade/* -rf
echo "解压包${upgrade_pkg}..."
ls -l $upgrade_pkg
unzip $upgrade_pkg -d ./temp_upgrade 
#数据库配置到刚刚目录
echo "修改配置文件"
sleep 1
/bin/cp -f conf/$project_name/dbConfig.properties ./temp_upgrade/WEB-INF/classes/ 
echo "校验配置"
grep "env=prod" /data/tomcat/webapps/$project_name/WEB-INF/classes/dbConfig.properties
if [ $? -eq 0 ];then
   echo "配置OK!!!"
else 
   echo "配置ERROR!!!"
   exit 1
fi

#备份项目
echo "备份项目/data/tomcat/webapps/$project_name => ./backup/$project_name$time_subfix"
sleep 1
mv /data/tomcat/webapps/$project_name ./backup/$project_name$time_subfix
#备份文件路径写入到备份列表，方便版本回退
echo "./backup/$project_name$time_subfix" >>./backup/backuplist_${project_name}.txt
#升级项目
echo "升级项目"
sleep 1
mv ./temp_upgrade /data/tomcat/webapps/$project_name
#停止tomcat
bash restart_tomcat.sh
echo "停止tomcat"
sleep 1
tomcat_pid=$(ps aux |grep /data/tomcat|grep -v grep|awk '{ print $2}')
kill -9 $tomcat_pid
sleep 1
#启动tomcat
echo "启动tomcat"
sleep 1
/data/tomcat/bin/startup.sh
#循环读取日志文件10次获取日志
n=1
echo "查看日志"
while [ $n -le 3 ];do
    tail -10 /data/tomcat/logs/catalina.out
    sleep 1
    n=`expr $n + 1`
done
