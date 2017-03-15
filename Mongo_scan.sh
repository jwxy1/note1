#!/bin/bash
function mongoshell(){
ip=$1
port=$2
#生成临时文件保存 Mongo服务器IP PORT  客户端IP 操作访问的DB
clientlist=$(mongo --host $ip --port $port --quiet  <<EOF | egrep -v "\.\.\.|:SECONDARY|PRIMARY"| awk  '{  print substr($1,1,index($1,":")-1),substr($2,1,index($2,".")-1)}'
var obj=db.currentOp()
for(var  i in obj.inprog){
if( typeof(obj.inprog[i].client ) != "undefined" )
{
if(obj.inprog[i].client != "")
print(obj.inprog[i].client,obj.inprog[i].ns)}}
EOF)
echo  "$clientlist"
}

function mongoshell2(){
ip=$1
port=$2
cd $(dirname $0)
#生成临时文件保存 Mongo服务器IP PORT  客户端IP 操作访问的DB
mongo --host $ip --port $port --quiet  <<EOF | egrep -v "\.\.\.|:SECONDARY|PRIMARY"| awk -v _ip=$ip -v _port=$port '{print _ip,_port,substr($1,1,index($1,":")-1),substr($2,1,index($2,".")-1)}'  >> $$.tmp
var obj=db.currentOp()
for(var  i in obj.inprog){
if( typeof(obj.inprog[i].client ) != "undefined" )
{
print(obj.inprog[i].client,obj.inprog[i].ns)}}
EOF
}

function pythonshell(){
ip=$1
_key=$2
jsondata=$(curl -s http://api.cmdb.dp/api/v0.1/ip/$ip/products)
_value=$(echo $jsondata | python -c 'import json, sys;reload(sys);sys.setdefaultencoding("utf8");s=json.load(sys.stdin)["products"][0]["'$_key'"];print s.encode("utf8")' 2>/dev/null )

if [ $? -ne 0 ];
then
jsondata=$(curl -s http://api.cmdb.dp/api/v0.1/ip/$ip/bu)
_value=$(echo $jsondata | python -c 'import json, sys;reload(sys);sys.setdefaultencoding("utf8");s=json.load(sys.stdin)["bu"][0]["'$_key'"];print s.encode("utf8")' 2>/dev/null )
[ $? -eq 0 ] && echo $_value || echo error!|$ip|$_key
else
 echo $_value
fi
}


function restore(){
sort -u ./*.tmp  | while read record;
do

_product_name=""
_product_owner=""
_set=""
_ip=""
_port=""
_state=""

count=0
for i in $record;
do
[ $count -eq 0 ] && _bg_name=$i
[ $count -eq 1 ] && _product_name=$i
[ $count -eq 2 ] && _product_owner=$i
[ $count -eq 3 ] && _set=$i
[ $count -eq 4 ] && _ip=$i
[ $count -eq 5 ] && _port=$i
[ $count -eq 6 ] && _state=$i
let count++
done;
mysql_cmd="replace  into DP_Mongo_detail(bg_name,product_name,product_owner,\`set\`,ip,port,state) select \"$_bg_name\",\"$_product_name\",\"$_product_owner\",\"$_set\",\"$_ip\",\"$_port\",\"$_state\""
db="MonCenter";
mysql -umyadmin -p'Num@$%^C0ntal' -h10.1.1.209 $db --default-character-set=utf8  -e "$mysql_cmd" > /dev/null 2>&1
[ $? -eq 0 ] && echo inserted ok:$record || echo failed:$record
sleep 1
done;

}

#main
cd $(dirname $0)
mysql_cmd="select t.set,t.ip,t.port,t.state from DP_Mng_MongoRepl as t where env=1 and state in ('PRIMARY','SECONDARY') "
setlist=$(mysql -umyadmin -p'Num@$%^C0ntal' -h10.1.1.209 MonCenter -e"$mysql_cmd")
keylist=("bg_name" "product_name" "product_owner")
echo -e  "$setlist" | while read item;do
#echo item:$item >> $$.tmp;
count=0
for x in $item;
do
let count++
[ $count -eq 1 ] && Set=$x
[ $count -eq 2 ] && serverIP=$x
[ $count -eq 3 ] && serverPort=$x
[ $count -eq 4 ] && state=$x
done;
#mongoshell
clientlist="$(mongoshell $serverIP $serverPort)"
#begin  return obj
echo -e  "$clientlist" | while read clientline;do
#echo clientline:$clientline,length:${#clientline}
if [ ${#clientline} -gt 0 ];
then
count=0
for i in $clientline;
do
let count++
[ $count -eq 1 ] && clientIP=$i
[ $count -eq 2 ] && acessDB=$i
done;

#pythonshell
#遍历临时文件中的客户机IP 获得业务相关信息

count=0
for item in ${keylist[*]};
do
obj[$count]=$(pythonshell $clientIP $item)
let count++
done;

obj[$count]=$Set
let count++
obj[$count]=$serverIP
let count++
obj[$count]=$serverPort
let count++
obj[$count]=$state
echo ${obj[*]} >> $$.tmp

fi
done;
#end  return obj
done
tmpfilenums=$(ls -l  *.tmp1 2>/dev/null | wc -l)
[ $tmpfilenums -ge 5 ] &&  restore
[ $tmpfilenums -ge 10 ] && find ./ -maxdepth 1 -type f ! -newer $$.tmp -mmin +30  -name "*[0-9].tmp" -delete
