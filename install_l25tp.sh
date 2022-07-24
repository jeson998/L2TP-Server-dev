#!/bin/bash
l2tp_file="/usr/sbin/xl2tpd"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
install()
{
	[[ -e ${l2tp_file} ]] && echo -e "${Error} 检测到 xl2tpd 已安装 !" && exit 1
	wget --no-check-certificate https://raw.githubusercontent.com/jeson998/L2TP-Server-dev/master/l2tp.sh
	sleep 1
	chmod +x l2tp.sh
	./l2tp.sh 2>&1 <<eof
	192.168.254
	12345678
	test1
	123456
	y
eof
local_ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
echo "${local_ip}"
for nip in ${local_ip[*]}
        do
		echo "${nip}"
        	ipd=${nip##*.}
		touch /etc/xl2tpd/xl2tpd$ipd.conf
		echo "
				[global]
				ipsec saref = yes
				listen-addr = $nip
				[lns default]
				ip range = 192.168.$ipd.2-192.168.$ipd.254
				local ip = 192.168.$ipd.1
				require chap = yes
				refuse pap = yes
				require authentication = yes
				name = l2tpd
				ppp debug = yes
				pppoptfile = /etc/ppp/options.xl2tpd
				length bit = yes
			" > /etc/xl2tpd/xl2tpd$ipd.conf
		xl2tpd -c /etc/xl2tpd/xl2tpd$ipd.conf -p /var/run/xl2tpd$ipd.pid
		iptables -t nat -A POSTROUTING -s 192.168.$ipd.0/24 -j SNAT --to $nip
        done
        batchuser
}

addconfig()
{
	local_ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
	echo "${local_ip}"
	for nip in ${local_ip[*]}
        do
		echo "${nip}"
        	ipd=${nip##*.}
		touch /etc/xl2tpd/xl2tpd$ipd.conf
		echo "
				[global]
				ipsec saref = yes
				listen-addr = $nip
				[lns default]
				ip range = 192.168.$ipd.2-192.168.$ipd.254
				local ip = 192.168.$ipd.1
				require chap = yes
				refuse pap = yes
				require authentication = yes
				name = l2tpd
				ppp debug = yes
				pppoptfile = /etc/ppp/options.xl2tpd
				length bit = yes
			" > /etc/xl2tpd/xl2tpd$ipd.conf
		xl2tpd -c /etc/xl2tpd/xl2tpd$ipd.conf -p /var/run/xl2tpd$ipd.pid
		iptables -t nat -A POSTROUTING -s 192.168.$ipd.0/24 -j SNAT --to $nip
        done
}

adduser()
{
	echo "########## 添加用户 ###########"
	read -e -p "请输入用户名：" user
	read -e -p "请输入密码：" pass
	read -e -p "指定拨号分配的IP:" ipaddr
	echo "$user   *       $pass        $ipaddr" >> /etc/ppp/chap-secrets
	echo "用户名：$user ,密码：$pass ,共享密钥：12345678 "
}
batchuser()
{
	echo "########## 批量添加用户 ###########"
	read -e -p "请输入用户名前缀：" user
	read -e -p "请输入密码：" pass	
	for i in {11..19};do
		for j in {1..5};do
		while true
		do
			let m=$i-10
			lastip=$(($RANDOM%240+10))
			isexsit=`grep "192.168.$i.$lastip" /etc/ppp/chap-secrets`
			if [[ ! -z "${isexsit}" ]]
			then
				echo ""
			else
				echo "$user$m$j   *       $pass        192.168.$i.$lastip" >> /etc/ppp/chap-secrets
				echo "用户名：$user$m$j ， 密码：$pass  共享密钥：12345678"
				break
			fi
		done

		done		
	done

	for j in {110,120,130,140,150};do
		while true
		do
			lastip=$(($RANDOM%240+10))
			isexsit=`grep "192.168.4.$lastip" /etc/ppp/chap-secrets`
			if [[ ! -z "${isexsit}" ]]
			then
				echo ""
			else
				echo "$user$j   *       $pass        192.168.4.$lastip" >> /etc/ppp/chap-secrets
				echo "用户名：$user$j ， 密码：$pass  共享密钥：12345678"
				break
			fi
		done
	done
}

check_pid(){
        PID=`ps -ef| grep "xl2tpd"| grep -v "grep" | grep -v "init.d" |grep -v "service" |awk '{print $2}'`
}


echo && echo -e "  L2TP 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 L2TP
 ${Green_font_prefix} 2.${Font_color_suffix} 添加 账号
 ${Green_font_prefix} 3.${Font_color_suffix} 批量 账号
 ${Green_font_prefix} 4.${Font_color_suffix} 查看 账号
 ${Green_font_prefix} 5.${Font_color_suffix} 添加 配置
————————————" && echo
        if [[ -e ${l2tp_file} ]]; then
                check_pid
                if [[ ! -z "${PID}" ]]; then
                        echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
                else
                        echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
                fi
        else
                echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
        fi
        echo
        read -e -p " 请输入数字 [1-5]:" num
        case "$num" in
                1)
                install
                ;;
                2)
                adduser
                ;;
                3)
                batchuser
                ;;
                4)
                cat /etc/ppp/chap-secrets
                ;;
                5)
                addconfig
                ;;
                *)
                echo "请输入正确数字 [0-5]"
                ;;
        esac
