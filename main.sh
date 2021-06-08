 #!/bin/bash
now=`date -u -d"+8 hour" +'%Y-%m-%d %H:%M:%S'`
#cpu use threshold
cpu_warn='75'
 #mem idle threshold
mem_warn='100'
 #disk use threshold
disk_warn='90'
 # clear old log file
 >/tmp/capa.log
#---cpu
item_cpu () {
cpu_idle=`top -b -n 1 | grep Cpu | awk '{print $8}'|cut -f 1 -d "."`
cpu_use=`expr 100 - $cpu_idle`
 echo "$now current cpu utilization rate of $cpu_use" >> /tmp/capa.log
if [ $cpu_use -gt $cpu_warn ]
    then
        echo "cpu warning!!!"
    else
        echo "cpu ok!!!"
fi
}
#---mem
item_mem () {
 #MB units
mem_free=`free -m | grep "Mem" | awk '{print $4+$6}'`
 echo "$now the current memory space remaining ${mem_free} MB" >> /tmp/capa.log
if [ $mem_free -lt $mem_warn  ]
    then
        echo "mem warning!!!"
    else
        echo "mem ok!!!"
fi
}
#---disk
item_disk () 
{
disk_use=`df -P | grep /dev | grep -v -E '(tmp|boot)' | awk '{print $5}' | cut -f 1 -d "%"`
disk_path=`df -P | grep /dev | grep -v -E '(tmp|boot)' | awk '{print $5,"utlized by",$6,"filesystem"}'`
echo "$now current disk usage is and $disk_path">> /tmp/capa.log
if [ $disk_use -gt $disk_warn ]
    then
        echo "disk warning!!!"
    else
        echo "disk ok!!!"
fi
}
item_cpu
item_mem
item_disk

cat /tmp/capa.log



SUBJECT= "Resource alert - daily "
RECEIVER= "YOUR EMIAL" 
TEXT=  `cat /tmp/capa.log` 

SERVER_NAME=$HOSTNAME  
SENDER=$(whoami)  
USER="noreply"



MAIL_TXT="Subject: $SUBJECT\nFrom: $SENDER\nTo: $RECEIVER\n\n$TEXT"  
echo -e $MAIL_TXT | sendmail -t  
exit $?  