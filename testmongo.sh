#!/bin/bash
#!/bin/bash
function mongoshell(){
ip=$1
port=$2
cd $(dirname $0)
#生成临时文件保存 Mongo服务器IP PORT  客户端IP 操作访问的DB
clientlist=$(mongo --host $ip --port $port --quiet  <<EOF | egrep -v "\.\.\.|:SECONDARY|PRIMARY"| awk  '{ if("x"$1!="x") print substr($1,1,index($1,":")-1),substr($2,1,index($2,".")-1)}'
var obj=db.currentOp()
for(var  i in obj.inprog){
if( typeof(obj.inprog[i].client ) != "undefined" )
{
print(obj.inprog[i].client,obj.inprog[i].ns)}}
EOF)
echo "$clientlist"
}

function mongoshell2222(){
ip=$1
port=$2
cd $(dirname $0)
#生成临时文件保存 Mongo服务器IP PORT  客户端IP 操作访问的DB
clientlist=$(mongo --host $ip --port $port --quiet  <<EOF | egrep -v "\.\.\.|:SECONDARY|PRIMARY"| awk -v _ip=$ip -v _port=$port '{print _ip,_port,substr($1,1,index($1,":")-1),substr($2,1,index($2,".")-1)}'
var obj=db.currentOp()
for(var  i in obj.inprog){
if( typeof(obj.inprog[i].client ) != "undefined" )
{
print(obj.inprog[i].client,obj.inprog[i].ns)}}
EOF)

[[ "$clientlist"x != 'x' ]] && echo "$clientlist"
}

res=$( mongoshell2222 $1 $2)
echo -n  $res 
