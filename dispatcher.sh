#!/bin/bash
url="https://mts-olimp-cloud.codenrock.com/api"
token="o7e7QThoMe8U6AoI80qVDL98mmGk9GE3"
key="1"
file="./statistic.log"
c1='[\n\r ]'    # delete  \n, \r, [, ] and spaces
c2='s/},{/\n/g' # replace },{  with  \n
c3='}{' # delete { and }
op=7    # min nummber for optimizing 
function help {
  echo "========================"
  echo "Press a key for:"
  echo "   q - quit"
  echo "   h - show this message"
  echo "   p - get prices"
  echo "   s - show statistic"
  echo "   r - show resources"
  echo "   c - create resource"
  echo "   d - delete resource"
  echo "   u - update resource"
  echo "   e - delete all resources and exit"

  echo "========================"
  echo ""
  } # help
function start_log {
  while true; do \
    echo $(curl -s -X 'GET' \
      -H 'accept: */*' \
      "$url/statistic?token=$token" \
      | tr -d ' \n}{')  >> $file; \
      sleep 180;
  done &
  # cat statistic.log \
  #     | jq   ' \
  #             .timestamp +  "# " + \
  #             (.cost_total | tostring) +  \
  #             "  online: " + (.online_time| tostring) + \
  #             ", offline: " + (.offline_time| tostring) + \
  #             " requests: " + (.requests|tostring)'
  #
  } # start_log
function get_prices {
  curl -s -X 'GET' -H 'accept: */*' "$url/price" \
    | tr -d ' \n[]' | sed 's/},{/\n/g' | tr -d '{}'
  echo
  } # get_prices
function show_statistic {
  echo "=== currently statistic ==="
  if [ -f $file ]
  then
	  cat $file | cut -d, -f1,4,6,15,19,24,26  | tail -n 15
  else
	  echo "file: $file not found"
  fi
  echo "=== currently statistic ==="
  echo
  } # show_statistic
function show_resources {
  # #
    #    1  "cost":8
    #    2  "cpu":10
    #    3  "cpu_load":0.124444
    #    4  "failed":false
    #    5  "failed_until":"2023-10-19T10:36:03"
    #    6  "id":313493
    #    7  "ram":10
    #    8  "ram_load":0.626036
    #    9  "type":"vm"
  get_resources
  echo $resource_csv | tr ';' '\n' | tr ' ' ',' \
  | awk -F ','  -v db="" -v vm="" -v vm_n=0 -v db_n=0 -v OFS='\t'  '
    { 
         if($9 == "vm"){
           if (vm_n % 20 == 0) vm=vm"vms\tid\tcost\tnums\tcpu_load\tram_load\n"
           vm_cost+=$1
           vm_cpu+=$2
           vm_cpu_load+=$3*$2
           vm_ram+=$7
           vm_ram_load+=$8*$7
           vm_n+=1
           vm=vm""vm_n"\t"$6"\t"$1"\t"$2"\t"$3"\t"$8"\n"
         } else if($9 == "db") {
           if (db_n % 20 == 0) db=db"dbs\tid\tcost\tnums\tcpu_load\tram_load\n"
           db_cost+=$1
           db_cpu+=$2
           db_cpu_load+=$3*$2
           db_ram+=$7
           db_ram_load+=$8*$7
           db_n+=1 
           db=db""db_n"\t"$6"\t"$1"\t"$2"\t"$3"\t"$8"\n"
         }
       }
   END {
        print vm
        print db
         print "type\t#\tcost\tnumber\tcpu_load\tram_load"
         print "vm",vm_n,vm_cost,vm_cpu,vm_cpu_load,vm_ram_load 
         print "db",db_n,db_cost,db_cpu,db_cpu_load,db_ram_load 
       }'
  echo
  } # show_resources
function get_resources { # output $resource_csv 
  #    1	"cost":9
  #    2	"cpu":10
  #    3	"cpu_load":2.11745
  #    4	"failed":false
  #    5	"failed_until":"2023-10-16T08:18:05"
  #    6	"id":253639
  #    7	"ram":10
  #    8	"ram_load":2.25807
  #    9	"type":"db"
  resource_csv=$(curl -s \
	  -X 'GET' -H 'accept: */*' "$url/resource?token=$token" \
	  | tr -d "$c1" |sed -e $c2 |tr -d "$c3" | tr ',' '\t' \
    | awk '{gsub(/"[a-z_]*":/,"");gsub(/"/,"");print $0}' \
    | tr '\n' ';' | sed -e 's/;$//')
  } # get_resources
function show_status {
  #
    # 1  "availability":0.0778466
    # 2  "cost_total":92962
    # 3  "db_cpu":31
    # 4  "db_cpu_load":26.1255
    # 5  "db_ram":31
    # 6  "db_ram_load":31.932
    # 7  "id":1330
    # 8  "last1":117
    # 9  "last15":1907
    #10  "last5":593
    #11  "lastDay":102682
    #12  "lastHour":7892
    #13  "lastWeek":260631
    #14  "offline_time":7143
    #15  "online":true
    #16  "online_time":603
    #17  "requests":7899
    #18  "requests_total":79558622
    #19  "response_time":91
    #20  "timestamp":"2023-10-19T19:02:58"
    #21  "user_id":1330
    #22  "user_name":"cnrprod-team-53558"
    #23  "vm_cpu":111
    #24  "vm_cpu_load":7.65668
    #25  "vm_ram":111
    #26  "vm_ram_load":38.8239
  fields_s="availability,cost_total,db_cpu,db_cpu_load,db_ram,db_ram_load,id,last1,last15,last5,lastDay,lastHour,lastWeek,offline_time,online,online_time,requests,requests_total,response_time,timestamp,user_id,user_name,vm_cpu,vm_cpu_load,vm_ram,vm_ram_load"
  echo $fields_s | awk -v OFS='\n' -F ',' '{
    print $20,$1,$15,$19,$4,$6,$24,$26
  }'
  echo -en "\033[8A\033[15C"
  #     print length($1),length($4),length($6),length($15),length($19),length($24),length($26)
  curl -s -X 'GET' -H 'accept: */*' "$url/statistic?token=$token"\
	  |tr -d ' {}' |sed -e 's/".*"://g' | tr -d '"\n'\
    | awk -v OFS='' -F ',' -v OFS='\n\033[15C'  '{print $20,$1,$15,$19,$4,$6,$24,$26}'
  echo
  } # show_status
function create_resource {
  if [ -z "$type" ]
  then
    echo "       === create resource ==="
    echo
    get_type 
    echo
  fi  
  curl -s -X 'POST' -H 'accept: */*' \
    "$url/resource?token=$token" \
    -H 'Content-Type: application/json' \
    -d "$type" | tr -d '\n ' | cut -d, -f1,2,5,6,9
 } # create_resource
function update_resource {
  get_resources
  echo
  echo $resource_csv | tr ';' '\n' | nl
  echo
  echo -n "please input resource # for updte or ENTER for first item: "
  read id
  echo
  [ -z $id  ] && id=1
  id=$(echo $resource_csv | tr ';' '\n' | awk -v id=$id '{
    n+=1
    if ($0 != "" && n == id ) {print $6}
  }')
  echo
  get_type 
  curl -s -X 'PUT' -H 'accept: */*'\
       -H 'Content-Type: application/json' \
       "$url/resource/$id?token=$token" -d "$type" \
       | tr -d '\n ' | cut -d, -f1,2,5,6,9
  echo
  echo
  } # update_resource
function optimise {
  get_resources
  type="{\"type\":\"${t}\",\"cpu\":8,\"ram\": 8}"
  f=$(echo $resource_csv | tr ';' '\n' | awk -v t=$t -v op=$op -v a="" '{
      if ($0 != "" && $4 == "false" && $9 == t && $1 == 1) {
        if (a==""){a=$6}
        else {a=a" "$6}
        n+=1;if (n == op){exit}
      }
    } 
    END {
      if (n < op) {print "false"}
      else { print a }
    }')
  [ "$f" == "false" ] && return
  echo "optimize :$t: $f" #&& echo && return
  n=1
  for id in $f
    do
    [ -z "$id" ] && continue
    [ $n == 1 ] &&  n=0 && \
      curl -s -X 'PUT' -H 'accept: */*' \
      -H 'Content-Type: application/json' \
      "$url/resource/$id?token=$token" -d "$type" \
      | tr -d '\n ' | cut -d, -f1,2,5,6,9 && continue
    curl -s -X 'DELETE' -H 'accept: */*' \
    "$url/resource/$id?token=$token" | tr -d '\n ' | cut -d, -f1,2,5,6,9
    done
  } #optimise
function delete_resource {
  get_resources
  if [ -z "$id" ]
    then
    echo
    echo $resource_csv | tr ';' '\n' | nl
    echo
    echo -n "please input resource # for delete or ENTER for first item: "
    read id
    echo
    fi
  [ -z "$id"  ] && id=1
  id=$(echo $resource_csv | tr ';' '\n' | awk -v id=$id '{
    if ($0 != "" && $3 > 0 && $8 > 0){
      if (NR == id ) {print $6; exit}
      else if ($9 == id && $4 == "false") {print $6; exit}
    }
  }')
  [ "$id" != "" ] && curl -s -X 'DELETE' -H 'accept: */*' "$url/resource/$id?token=$token"
  echo
  echo
  } # delete_resource
function stop_dispatcher {
  get_resources
  ids=$(echo $resource_csv | tr ';' '\n' | awk   '{print $6}' | tr '\n' ' ' ) 
  for id in $ids
  do
    echo "delete : "
    [ "$id" != "" ] && curl -s -X 'DELETE' -H 'accept: */*' "$url/resource/$id?token=$token"
  done
  echo "bye bye" 
  exit 1
  } # stop_dispatcher
function get_type { # output   $type
  echo
  echo "1 - type: vm, cpu: 1,  ram: 2"
  echo "2 - type: vm, cpu: 8, ram: 8"
  echo "3 - type: db, cpu: 1,  ram: 2"
  echo "4 - type: db, cpu: 8, ram: 8"
  type='{"type":"vm","cpu":1,"ram": 2}';
  echo -n "Please select a resource type (1-4)[1]: "
  read -n 1 -s d
  case $d in
    1) type='{"type":"vm","cpu":1,"ram": 2}';;
    2) type='{"type":"vm","cpu":8,"ram": 8}';;
    3) type='{"type":"db","cpu":1,"ram": 2}';;
    4) type='{"type":"db","cpu":8,"ram": 8}';;
    *)echo "invalid key , set 1";;
  esac
  } # get_type
function calculate {
  res=$(curl -s -X 'GET' -H 'accept: */*' "$url/resource?token=$token" \
    | tr -d ' \n[]' | sed -e 's/},{/\n/g' | tr -d '}{' \
    | awk -F ',' -v OFS=',' -v vm_f='false' -v db_f='false' \
        -v vm_n1=0 -v vm_n2=0 -v db_n1=0 -v db_n2=0 '{
        gsub(/"[a-z_]*":/,""); gsub(/"/,"")
        if($9 == "vm"){
          vm_n+=1
          vm_cost+=$1
          if ($1 == "1")  {vm_n1+=1}
	      else {vm_n2+=1} 
          vm_cpu+=$2;         vm_ram+=$7
          vm_cpu_load+=$3*$2; vm_ram_load+=$8*$7
          if($4 == "true") {vm_f = "true"}
          if($3 == "0.0") {vm_f = "true"}
        } else if($9 == "db") {
          db_n+=1
          db_cost+=$1
          if ($1 == "1") {db_n1+=1}
	      else { db_n2+=1} 
          db_cpu+=$2; db_ram+=$7
          db_cpu_load+=$3*$2; db_ram_load+=$8*$7
          if($4 == "true") {db_f = "true"}
          if($3 == "0.0") {db_f = "true"}
        }
    }
    END {
        print "vm",vm_n,vm_cost,vm_cpu,vm_cpu_load,vm_ram,vm_ram_load,vm_f,vm_n1,vm_n2
        print "db",db_n,db_cost,db_cpu,db_cpu_load,db_ram,db_ram_load,db_f,db_n1,db_n2
    }' | tr '\n' ' ')
  s=0
  for item in $res
  do
    t=$(echo $item | cut -d, -f1)
    n=$(echo $item | cut -d, -f2) 
    n1=$(echo $item | cut -d, -f9) 
    n2=$(echo $item | cut -d, -f10)
    c=$(echo $item | cut -d, -f5 | sed -e 's/\..*//')
    r=$(echo $item | cut -d, -f7 | sed -e 's/\..*//')
    f=$(echo $item | cut -d, -f8)
    type="{\"type\":\"${t}\",\"cpu\":1,\"ram\": 2}"
    if [ -z "$n" ]
    then echo; echo "create $t: $c $r $f"; s=1; create_resource
    else
      if [ $c -gt 60 ] || [ $r -gt 60 ] #&& [ $f == "false" ] 
      then
        echo; echo "create $t: $c $r $f"; s=1
        [ $c -gt 75 ] || [ $r -gt 75 ] && type="{\"type\":\"${t}\",\"cpu\":8,\"ram\": 8}"
        create_resource
      else 
	      if [ $c -lt 40 ] && \
		 [ $r -lt 40 ] && \
		 [ $c -ne 0 ]  && \
		 [ $r -ne 0 ]  && \
		 [ $n -ne 1 ] 
        then  id=$t; echo; echo -en "delete $t: $c $r => "; s=1; delete_resource
        fi
      fi
    fi
    if [ $n1 -ge "$op" ]
    then
      s=1; optimise
    fi
  done
  [ $s -eq 1 ] && show_status
  } # calculate
##########################
#        main            #
##########################
echo -en "\033[2J"
help
show_status
calculate
od=$(date -d "40 seconds" +%H%M%S)
while [ -z $key ] || [ $key != "q" ]  # wait for quit
do
  if [ $od -lt $(date +%H%M%S) ]
  then
    calculate
    od=$(date -d "40 seconds" +%H%M%S)
    echo -en "\033[9A"
    show_status
  fi
  echo -en "\033[s"
  echo -n $(date -d '2 hour ago' +%H:%M:%S)
  read -p " your choice?" -t 1 -n 1 -s key
  echo -en "\033[u"
  case $key in
    h) help; show_status;;
    s) show_statistic; show_status;;
    r) echo "=== current resources ==="; 
       show_resources; show_status;;
    c) type=""; create_resource; show_status;;
    d) id=""; delete_resource; show_status;;
    u) update_resource; show_status;;
    p) echo "=== prices ===";
       get_prices; show_status;;
    e) stop_dispatcher;;
  esac
done
echo "bye bye" 
