#
# bash functions
#

# start or stop smb service
#
sc() {
	case "$1" in
		smb)
			local services='nmbd smbd'
			;;
		dlna)
			local services='minidlna'
			;;
		ssh|sshd)
			local services='ssh'
			;;
		*)
			echo -e "Usage: ${FUNCNAME[0]} service_name [start|stop|restart]\n"
			return
			;;
	esac

	case "$2" in
		start)
			local action1=enable
			local action2=start
			;;
		stop)
			local action1=disable
			local action2=stop
			;;
		restart)
			local action1=enable
			local action2=restart
			;;
		*)
			echo -e "Usage: ${FUNCNAME[0]} service_name [start|stop|restart]\n"
			;;
	esac

	for s in $services ;do
		test -n "$action1" && (sudo systemctl $action1 $s)
		test -n "$action2" && (sudo systemctl $action2 $s; if [ "$action2" = stop ];then sudo killall $s ;fi;sleep 1)
		sudo systemctl -l --no-pager status $s;
		sudo ps -ef | grep -e $s | grep -v -e grep
		echo
	done
}

nt() {
	case "$1" in
		home)
			sudo sed -i -e 's/^\(address1.*192.168.5.232.*\)/#\1/' \
				-e 's/method=manual/method=auto/' \
				/etc/NetworkManager/system-connections/有线连接
			sudo systemctl restart NetworkManager
			sleep 1
			ip a l
			;;
		office)
			sudo sed -i -e 's/method=auto/method=manual/' \
				/etc/NetworkManager/system-connections/有线连接
			#sudo sed -i -e 's/^#\(address1.*192.168.5.232.*\)/\1/' \
			#	/etc/NetworkManager/system-connections/有线连接 || \
			sudo sed -i -e '/ipv4/a\address1=192.168.5.232\/21,192.168.0.253' \
				/etc/NetworkManager/system-connections/有线连接
			sudo systemctl restart NetworkManager
			sleep 1
			ip a l
			;;
		*)
			echo -e "Usage: ${FUNCNAME[0]} [home|office]\n"
			sudo cat /etc/NetworkManager/system-connections/有线连接
			echo
			ip a l
			;;
	esac
}
