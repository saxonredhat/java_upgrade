echo "停止tomcat"
sleep 1
tomcat_pid=$(ps aux |grep /data/tomcat|grep -v grep|awk '{ print $2}')
kill -9 $tomcat_pid
sleep 1
#启动tomcat
echo "启动tomcat"
sleep 1
/data/tomcat/bin/startup.sh
