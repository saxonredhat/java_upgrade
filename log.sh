n=1
echo "查看日志"
while [ $n -le 20 ];do
    tail -10 /data/tomcat/logs/catalina.out
    sleep 1
    n=`expr $n + 1`
done
