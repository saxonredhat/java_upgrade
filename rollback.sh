#参数获取项目名
project=$1
rollback_num=${2:-'-9999999'}
time_subfix=$(date +%Y%m%d%H%M%S)

if [ x"$project" == x"q" ];then
    project_name="qsb"
elif [ x"$project" == x"qb" ];then
    project_name="qsbBackstage"
else
    echo "脚本执行格式如下:./rollback.sh q|qb -N "
    echo "q代表qsb项目，qb代表qsbBackstage项目,N代码回退到的之前第几个版本，如上个版本则为:-1,上上个版本:-2"
    exit 1
fi

#备份需要回退的项目
backup_num=$(wc -l ./backup/backuplist_${project_name}.txt|awk '{ print $1}')
rollback_num2=$(echo $rollback_num|sed 's/-//')
if [ $rollback_num2 -gt $backup_num ];then
    echo "回退版本号失败,最多回退: -${backup_num}"
    echo "备份列表如下:"
    cat ./backup/backuplist_${project_name}.txt
    exit 1
fi
#备份
echo "备份项目"
sleep 1
mv /data/tomcat/webapps/$project_name ./backup/${project_name}_rollback_$time_subfix

rollback_file=$(tail $rollback_num ./backup/backuplist_${project_name}.txt|head -1)
mkdir /data/tomcat/webapps/$project_name
echo "回退项目:$rollback_file => /data/tomcat/webapps/$project_name"
sleep 1
/bin/cp -rf $rollback_file/* /data/tomcat/webapps/$project_name

echo "校验配置"
sleep 1
grep "env=prod" /data/tomcat/webapps/$project_name/WEB-INF/classes/dbConfig.properties
if [ $? -eq 0 ];then
   echo "配置OK!!!"
else
   echo "配置ERROR!!!"
   exit 1
fi


#重启tomcat
bash restart_tomcat.sh
#循环读取日志文件10次获取日志
n=1
echo "查看日志"
while [ $n -le 3 ];do
    tail -10 /data/tomcat/logs/catalina.out
    sleep 1
    n=`expr $n + 1`
done
