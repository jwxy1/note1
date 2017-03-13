#!/bin/bash

function pythonshell(){
ip=$1
_key=$2
jsondata=$(curl -s http://api.cmdb.dp/api/v0.1/ip/$ip/products)
_value=$(echo $jsondata | python -c 'import json, sys;reload(sys);sys.setdefaultencoding("utf8");s=json.load(sys.stdin)["products"][0]["'$_key'"];print s.encode("utf8")' 2>/dev/null )

if [ $? -ne 0 ];
then
jsondata=$(curl -s http://api.cmdb.dp/api/v0.1/ip/$ip/bu)
_value=$(echo $jsondata | python -c 'import json, sys;reload(sys);sys.setdefaultencoding("utf8");s=json.load(sys.stdin)["bu"][0]["'$_key'"];print s.encode("utf8")' 2>/dev/null )
[ $? -eq 0 ] && echo $_value || echo error!
else
 echo $_value
fi
}
host=$1
keylist=("bg_name" "product_name" "product_owner")
count=0
for item in ${keylist[*]};
do
obj[$count]=`pythonshell $host $item`
let count++ 
done;

echo ${obj[*]}
