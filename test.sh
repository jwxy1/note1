#!/bin/bash

data="Review 10.1.1.174 27121 ARBITER"
mysql_cmd="select t.set,t.ip,t.port,t.state from DP_Mng_MongoRepl as t where env=1 limit 2"
setlist="$(mysql -umyadmin -p'Num@$%^C0ntal' -h10.1.1.209 MonCenter -e"$mysql_cmd")"
echo -e  "$setlist" | while read item;do  echo item:$item; done

