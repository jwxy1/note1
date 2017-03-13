#!/bin/bash

function restore(){
cd $(dirname $0)
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

restore
