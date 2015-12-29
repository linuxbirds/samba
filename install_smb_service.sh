#!/bin/bash

SCRIPT_NAME=$0
SMB_PATH=/share
SMB_USER=root

function func_check_system()
{
    [ "`id -u`" -ne "0" ] && echo "You must run as root user." && exit 0
    check_str=`grep "CentOS" /etc/issue`
    [ -z "$check_str" ] && echo "Not surport this system" && exit 0
    read -p "Please press Enter to continue..."
}

function func_install_from_internet()
{
    yum -y install samba samba-client
}

function func_init_config()
{
    SMB_CONFIG_FILE=/etc/samba/smb.conf
    mv -f $SMB_CONFIG_FILE ${SMB_CONFIG_FILE}.$$
    [ -f ./smb.conf.$1 ] && cp ./smb.conf.$1 /etc/samba/smb.conf -f
	if [ "$1" = "login" ];then
	cat >>/etc/samba/smb.conf<<EOF
[login]	
path = $SMB_PATH
valid users = $SMB_USER
writable = yes
EOF
    fi
	if [ "$1" = "anonymous" ];then
	    cat >>/etc/samba/smb.conf<<EOF
[public]
comment = Document root directory
path = /share
public = yes
writable = yes
guest ok = yes
EOF
	fi
    service smb start
    chkconfig smb on
    mkdir -p $SMB_PATH
    chown -R nobody:nobody $SMB_PATH
}

function func_disable_firewall()
{
    sed -i '/SELINUX/ c SELINUX=disabled' /etc/selinux/config
    setenforce 0
    iptables -F
    /etc/init.d/iptables save
    iptables -I INPUT -p tcp --dport 139 -j ACCEPT
    
}

function func_usage()
{
    echo -e "##############################################"
    echo -e "\tUsage:"
    echo -e "\t\t $SCRIPT_NAME install [anonymous | login]"
    echo -e "\t\t $SCRIPT_NAME remove"
    echo -e "##############################################"
    exit 0
}

function func_remove_smb_service()
{
    yum -y remove samba samba-client samba-common
}

func_check_system

case "$1" in
    install)
	[ -z "$2" ] && func_usage
	func_install_from_internet
	if [ "$2" = "anonymous" ];then
	    func_init_config "anonymous"
	elif [ "$2" = "login" ];then
	    func_init_config "login"
	    smbpasswd -a $SMB_USER
	fi
	func_disable_firewall
    ;;
    remove)
        func_remove_smb_service
    ;;
    *)
	func_usage
    ;;
esac

exit 0

