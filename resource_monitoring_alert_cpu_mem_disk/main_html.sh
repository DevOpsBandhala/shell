#!/bin/bash
now=`date -u -d"+8 hour" +'%Y-%m-%d %H:%M:%S'`
#cpu use threshold
cpu_warn='1'
#mem idle threshold
mem_warn='1'
#disk use threshold
disk_warn='1'
#clear old log file
>/tmp/capa.log
touch /tmp/error_email.log > /dev/null 2>&1
>/tmp/error_email.log

#hostname
HOST_NAME=`hostname`

cat << 'EOF' >> /tmp/error_email.log
<html>
<head>
<style>
table {border-width: 2px; border-style: solid; border-color: black; border-collapse: collapse; width: 50%;}
th {border-width: 3px; padding: 3px; border-style: solid; border-color: black; background-color: rgb(0, 255, 128);}
td {border-width: 1px; padding: 3px; border-style: solid; border-color: black; text-align: center;}
</style>
</head>
<body>

<table >
    <thead>
        <tr> 
            <th>Target</th>
            <th>Remark</th>
            <th>Status</th>
        </tr>
    </thead>
<tbody>
EOF

      echo "<tr>" >> /tmp/error_email.log
      echo "<td>Server Name</td>" >> /tmp/error_email.log
      echo "<td>"`hostname`"</td>" >> /tmp/error_email.log
      echo "<td>"NA"</td>" >> /tmp/error_email.log
      echo "</tr>">> /tmp/error_email.log
     

      echo "<tr>" >> /tmp/error_email.log
      echo "<td>Job Date</td>" >> /tmp/error_email.log
      echo "<td>"$now"</td>" >> /tmp/error_email.log
      echo "<td>"NA"</td>" >> /tmp/error_email.log
      echo "</tr>">> /tmp/error_email.log

   
#---cpu
item_cpu () {
cpu_idle=`top -b -n 1 | grep Cpu | awk '{print $8}'|cut -f 1 -d "."`
cpu_use=`expr 100 - $cpu_idle`
 
if [ $cpu_use -gt $cpu_warn ]
    then
       #echo "$now current cpu utilization rate of $cpu_use - FAIL ">> /tmp/error_email.log;
       
      echo "<tr>" >> /tmp/error_email.log
      echo "<td>Current cpu utilization rate</td>" >> /tmp/error_email.log
      echo "<td>"$cpu_use"</td>" >> /tmp/error_email.log
      echo "<td>FAIL</td>" >> /tmp/error_email.log
      echo "</tr>">> /tmp/error_email.log

 else
       echo "$now current cpu utilization rate of $cpu_use - PASS" >> /tmp/capa.log;
        #echo "cpu ok!!!"
       
fi
}

#---mem
item_mem () {
 #MB units
mem_free=`free -m | grep "Mem" | awk '{print $4+$6}'`
 
if [ $mem_free -lt $mem_warn  ]
    then
        #echo "$now the current memory space remaining ${mem_free} MB - FAIL" >> /tmp/error_email.log
        #echo "mem warning!!!"
      echo "<tr>" >> /tmp/error_email.log
      echo "<td>Current remaining memory space</td>" >> /tmp/error_email.log
      echo "<td>"$mem_free"</td>" >> /tmp/error_email.log
      echo "<td>FAIL</td>" >> /tmp/error_email.log
      echo "</tr>">> /tmp/error_email.log
        
    else
       # echo "mem ok!!!"
        echo "$now the current memory space remaining ${mem_free} MB - PASS" >> /tmp/capa.log
        
fi
}

#---disk
item_disk () 
{
disk_use=`df -P | grep /dev | grep -v -E '(tmp|boot)' | awk '{print $5}' | cut -f 1 -d "%"`
disk_path=`df -P | grep /dev | grep -v -E '(tmp|boot)' | awk '{print $5,"utlized by",$6,"filesystem"}'`

if [ $disk_use -gt $disk_warn ]
    then
        #echo "disk warning!!!"
        echo "$now current disk usage is and $disk_path - FAIL">> /tmp/error_email.log
        
    else
        #echo "disk ok!!!"
        echo "$now current disk usage is and $disk_path - PASS">> /tmp/capa.log
        
fi
}


item_disk_loop()
{
   df -mP | grep /dev | grep -v -E '(tmp|boot)' | awk '{print $1, $4, $5}' | cut -f 1 -d "%" |sort -r -n | \
   while read -r fs_name aval_space used_space; do if test $disk_warn -lt $used_space; then \
         #echo "$now current $fs_name utilized $used_space % of space and $aval_space MB space only available - FAIL">> /tmp/error_email.log ;\

      echo "<tr>" >> /tmp/error_email.log
      echo "<td>Currently $fs_name utilized $used_space % of space and available space </td>" >> /tmp/error_email.log
      echo "<td>"$aval_space"</td>" >> /tmp/error_email.log
      echo "<td>FAIL</td>" >> /tmp/error_email.log
      echo "</tr>">> /tmp/error_email.log


         else \
         echo "$now current $fs_name utilized $used_space % of space and $aval_space MB space are available - PASS">> /tmp/capa.log ;\
          fi; \
    done;
}
cat << 'EOF' >> /tmp/error_email.log
</tbody>
  
</table>

</body>
</html>
EOF

#--- main function
item_cpu
item_mem
#item_disk
item_disk_loop

#Check if any FAIL on the log then email will send.
cat /tmp/error_email.log | grep 'FAIL' > /dev/null 2>&1
if [ $? -eq 0 ]; then
    cat /tmp/capa.log
    #--- email configuration part
    SUBJECT="Resource Monitoring Alert -$HOST_NAME Date: $now"
    RECEIVER="YOUR EMIAL" 
    TEXT=`cat /tmp/error_email.log` 
    
    SERVER_NAME=$HOSTNAME  
    SENDER=$(whoami)  
    USER="noreply"
    
    

    MAIL_TXT="Subject: $SUBJECT\nFrom: $SENDER\nTo: $RECEIVER\n\n$TEXT"  
    echo -e $MAIL_TXT Content-Type: text/html | sendmail -t 
    exit $?;
else
    cat /tmp/capa.log 
     
    exit
fi