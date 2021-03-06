#!/bin/sh

 function core_netstat() {
 cat /proc/net/tcp6 /proc/net/tcp 2>/dev/null > /dev/shm/core_netstat
   awk '{print $2,$3,$4}' /dev/shm/core_netstat | awk '   
       BEGIN {
             #分割符    
           FS = "[ ]*|:" ;}
                   
         #开始统计IP数     
         ( $0 !~ /local_address/ ){
                 
         #统计ipv4     
         if (length($1) == 8)      
          { 
            local_ip_col4 = strtonum("0x"substr($1,1,2)) ;     
            local_ip_col3 = strtonum("0x"substr($1,3,2)) ;     
            local_ip_col2 = strtonum("0x"substr($1,5,2)) ;     
            local_ip_col1 = strtonum("0x"substr($1,7,2)) ;                
            rem_ip_col4 =  strtonum("0x"substr($3,1,2)) ;     
            rem_ip_col3 =  strtonum("0x"substr($3,3,2)) ;     
            rem_ip_col2 =  strtonum("0x"substr($3,5,2)) ;     
            rem_ip_col1 =  strtonum("0x"substr($3,7,2)) ;     
          }     
        else  
        #统计ipv6
         { 
           local_ip_col4 = strtonum("0x"substr($1,1,2)) ;     
           local_ip_col3 = strtonum("0x"substr($1,3,2)) ;     
           local_ip_col2 = strtonum("0x"substr($1,5,2)) ;     
           local_ip_col1 = strtonum("0x"substr($1,7,2)) ;                
           rem_ip_col4 =  strtonum("0x"substr($3,25,2)) ;     
           rem_ip_col3 =  strtonum("0x"substr($3,27,2)) ;     
           rem_ip_col2 =  strtonum("0x"substr($3,29,2)) ;     
           rem_ip_col1 =  strtonum("0x"substr($3,31,2)) ;     
         }      
           local_port = strtonum("0x"$2) ;   
           rem_port = strtonum("0x"$4) ;
                   
        #分析连接状态     
        if ( $5 ~ /06/ ) tcp_stat = "TIME_WAIT"    
        else if ( $5 ~ /02/ ) tcp_stat = "SYN_SENT"    
        else if ( $5 ~ /03/ ) tcp_stat = "SYN_RECV"    
        else if ( $5 ~ /04/ ) tcp_stat = "FIN_WAIT1"    
        else if ( $5 ~ /05/ ) tcp_stat = "FIN_WAIT2"    
        else if ( $5 ~ /01/ ) tcp_stat = "ESTABLISHED" ;     
        else if ( $5 ~ /07/ ) tcp_stat = "CLOSE"    
        else if ( $5 ~ /08/ ) tcp_stat = "CLOSE_WAIT"    
        else if ( $5 ~ /09/ ) tcp_stat = "LAST_ACK"    
        else if ( $5 ~ /0A/ ) tcp_stat = "LISTEN"    
        else if ( $5 ~ /0B/ ) tcp_stat = "CLOSING"    
        else if ( $5 ~ /0C/ ) tcp_stat = "MAX_STATES"      
        printf("%d.%d.%d.%d [%d] %d.%d.%d.%d [%d] %s\n",local_ip_col1,local_ip_col2,local_ip_col3,local_ip_col4,local_port,rem_ip_col1,rem_ip_col2,rem_ip_col3,rem_ip_col4,rem_port,tcp_stat);}'
}

