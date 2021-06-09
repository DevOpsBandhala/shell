 #!/bin/bash
now=`date -u -d"+8 hour" +'%Y-%m-%d %H:%M:%S'`
#cpu use threshold
cpu_warn='75'
#mem idle threshold
mem_warn='100'
#disk use threshold
disk_warn='90'
#clear old log file
 >/tmp/capa.log
#email errot count flag
EMAIL_FALG_COUNT=0


#---cpu
item_cpu () {
cpu_idle=`top -b -n 1 | grep Cpu | awk '{print $8}'|cut -f 1 -d "."`
cpu_use=`expr 100 - $cpu_idle`
 
if [ $cpu_use -gt $cpu_warn ]
    then
       echo "$now current cpu utilization rate of $cpu_use - FAIL ">> /tmp/capa.log
       let "EMAIL_FALG_COUNT=EMAIL_FALG_COUNT+1";
        #echo "cpu warning!!!"
    else
       echo "$now current cpu utilization rate of $cpu_use - PASS" >> /tmp/capa.log
        #echo "cpu ok!!!"
        let "EMAIL_FALG_COUNT=EMAIL_FALG_COUNT+0";
fi
}

#---mem
item_mem () {
 #MB units
mem_free=`free -m | grep "Mem" | awk '{print $4+$6}'`
 
if [ $mem_free -lt $mem_warn  ]
    then
        echo "$now the current memory space remaining ${mem_free} MB - FAIL" >> /tmp/capa.log
        #echo "mem warning!!!"
        let "EMAIL_FALG_COUNT=EMAIL_FALG_COUNT+1";
    else
       # echo "mem ok!!!"
        echo "$now the current memory space remaining ${mem_free} MB - PASS" >> /tmp/capa.log
        let "EMAIL_FALG_COUNT=EMAIL_FALG_COUNT+0";
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
        echo "$now current disk usage is and $disk_path - FAIL">> /tmp/capa.log
        let "EMAIL_FALG_COUNT=EMAIL_FALG_COUNT+1";
    else
        #echo "disk ok!!!"
        echo "$now current disk usage is and $disk_path - PASS">> /tmp/capa.log
        let "EMAIL_FALG_COUNT=EMAIL_FALG_COUNT+0";
fi
}

#--- main function
item_cpu
item_mem
item_disk

if [ $EMAIL_FALG_COUNT -gt 0 ] 
    then
            #--- email configuration part
            SUBJECT="Resource alert - daily "
            RECEIVER="YOUR EMIAL" 
            TEXT=`cat /tmp/capa.log` 

            SERVER_NAME=$HOSTNAME  
            SENDER=$(whoami)  
            USER="noreply"

            MAIL_TXT="Subject: $SUBJECT\nFrom: $SENDER\nTo: $RECEIVER\n\n$TEXT"  
            echo -e $MAIL_TXT | sendmail -t 
            exit $?;
    else
            cat /tmp/capa.log
            #echo $EMAIL_FALG_COUNT;
            exit
fi