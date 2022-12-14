#!/bin/bash

# Secure WireGuard server installer


RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'

function isRoot() {
	if [ "${EUID}" -ne 0 ]; then
		echo "You need to run this script as root"
		exit 1
	fi
}

function checkVirt() {
	if [ "$(systemd-detect-virt)" == "openvz" ]; then
		echo "OpenVZ is not supported"
		exit 1
	fi

	if [ "$(systemd-detect-virt)" == "lxc" ]; then
		echo "LXC is not supported (yet)."
		echo "WireGuard can technically run in an LXC container,"
		echo "but the kernel module has to be installed on the host,"
		echo "the container has to be run with some specific parameters"
		echo "and only the tools need to be installed in the container."
		exit 1
	fi
}

function checkOS() {
	# Check OS version
	if [[ -e /etc/debian_version ]]; then
		source /etc/os-release
		OS="${ID}" # debian or ubuntu
		if [[ ${ID} == "debian" || ${ID} == "raspbian" ]]; then
			if [[ ${VERSION_ID} -lt 10 ]]; then
				echo "Your version of Debian (${VERSION_ID}) is not supported. Please use Debian 10 Buster or later"
				exit 1
			fi
			OS=debian # overwrite if raspbian
		fi
	elif [[ -e /etc/almalinux-release ]]; then
		source /etc/os-release
		OS=almalinux
	elif [[ -e /etc/fedora-release ]]; then
		source /etc/os-release
		OS="${ID}"
	elif [[ -e /etc/centos-release ]]; then
		source /etc/os-release
		OS=centos
	elif [[ -e /etc/oracle-release ]]; then
		source /etc/os-release
		OS=oracle
	elif [[ -e /etc/arch-release ]]; then
		OS=arch
	else
		echo "Looks like you aren't running this installer on a Debian, Ubuntu, Fedora, CentOS, AlmaLinux, Oracle or Arch Linux system"
		exit 1
	fi
}

function initialCheck() {
	isRoot
	checkVirt
	checkOS
}

function installQuestions() {
	echo "Welcome to the WireGuard installer!"
	echo "The git repository is available at: https://github.com/angristan/wireguard-install"
	echo ""
	echo "I need to ask you a few questions before starting the setup."
	echo "You can leave the default options and just press enter if you are ok with them."
	echo ""

	# Detect public IPv4 or IPv6 address and pre-fill for the user
	SERVER_PUB_IP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1)
	if [[ -z ${SERVER_PUB_IP} ]]; then
		# Detect public IPv6 address
		SERVER_PUB_IP=$(ip -6 addr | sed -ne 's|^.* inet6 \([^/]*\)/.* scope global.*$|\1|p' | head -1)
	fi
	read -rp "IPv4 or IPv6 public address: " -e -i "${SERVER_PUB_IP}" SERVER_PUB_IP

	# Detect public interface and pre-fill for the user
	SERVER_NIC="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"
	until [[ ${SERVER_PUB_NIC} =~ ^[a-zA-Z0-9_]+$ ]]; do
		read -rp "Public interface: " -e -i "${SERVER_NIC}" SERVER_PUB_NIC
	done

	until [[ ${SERVER_WG_NIC} =~ ^[a-zA-Z0-9_]+$ && ${#SERVER_WG_NIC} -lt 16 ]]; do
		read -rp "WireGuard interface name: " -e -i wg0 SERVER_WG_NIC
	done

	until [[ ${SERVER_WG_IPV4} =~ ^([0-9]{1,3}\.){3} ]]; do
		read -rp "Server's WireGuard IPv4: " -e -i 10.66.66.1 SERVER_WG_IPV4
	done

	until [[ ${SERVER_WG_IPV6} =~ ^([a-f0-9]{1,4}:){3,4}: ]]; do
		read -rp "Server's WireGuard IPv6: " -e -i fd42:42:42::1 SERVER_WG_IPV6
	done



	echo ""
	echo "Okay, that was all I needed. We are ready to setup your WireGuard server now."
	echo "You will be able to generate a client at the end of the installation."
	read -n1 -r -p "Press any key to continue..."
}
function installWireGuard() {
	# Run setup questions first
	installQuestions
	# Install WireGuard tools and module
	if [[ ${OS} == 'ubuntu' ]] || [[ ${OS} == 'debian' && ${VERSION_ID} -gt 10 ]]; then
		apt-get update
        echo ${OS} && ${VERSION_ID}
		#apt-get install -y wireguard iptables resolvconf qrencode
	elif [[ ${OS} == 'debian' ]]; then
		#if ! grep -rqs "^deb .* buster-backports" /etc/apt/; then
		#	echo "deb http://deb.debian.org/debian buster-backports main" >/etc/apt/sources.list.d/backports.list
		#	apt-get update
		#fi
         echo ${OS} && ${VERSION_ID}
		#apt update
		#apt-get install -y iptables resolvconf qrencode
		#apt-get install -y -t buster-backports wireguard
	elif [[ ${OS} == 'fedora' ]]; then
		if [[ ${VERSION_ID} -lt 32 ]]; then
		#	dnf install -y dnf-plugins-core
		#	dnf copr enable -y jdoss/wireguard
		#	dnf install -y wireguard-dkms
		#fi
		#dnf install -y wireguard-tools iptables qrencode
	elif [[ ${OS} == 'almalinux' ]]; then
		#dnf -y install epel-release elrepo-release
		#dnf -y install wireguard-tools iptables qrencode
		if [[ ${VERSION_ID} == 8* ]]; then
	#		dnf -y install kmod-wireguard
    echo ${OS} && ${VERSION_ID}
		fi
	elif [[ ${OS} == 'centos' ]]; then
		#yum -y install epel-release elrepo-release
         echo ${OS} && ${VERSION_ID}
		if [[ ${VERSION_ID} -eq 7 ]]; then
		#	yum -y install yum-plugin-elrepo
         echo ${OS} && ${VERSION_ID}
		fi
		#yum -y install kmod-wireguard wireguard-tools iptables qrencode
         echo ${OS} && ${VERSION_ID}
	elif [[ ${OS} == 'oracle' ]]; then
		#dnf install -y oraclelinux-developer-release-el8
		#dnf config-manager --disable -y ol8_developer
		#dnf config-manager --enable -y ol8_developer_UEKR6
		#dnf config-manager --save -y --setopt=ol8_developer_UEKR6.includepkgs='wireguard-tools*'
		#dnf install -y wireguard-tools qrencode iptables
	elif [[ ${OS} == 'arch' ]]; then
		#pacman -S --needed --noconfirm wireguard-tools qrencode
         echo ${OS} && ${VERSION_ID}
	fi

}
function newClient() {
	ENDPOINT="${SERVER_PUB_IP}:${SERVER_PORT}"
	echo ""
	echo "Tell me a name for the client."
	echo "The name must consist of alphanumeric character. It may also include an underscore or a dash and can't exceed 15 chars."
	

function uninstallWg() {
	echo "Now this function disabled"
	
}
function manageMenu() {
	echo "Welcome to WireGuard-install!"
	echo "The git repository is available at: "
	echo ""
	echo "It looks like WireGuard is already installed."
	echo ""
	echo "What do you want to do?"
	echo "   1) Add a new user"

	echo "   3) Uninstall WireGuard"
	echo "   4) Exit"
	until [[ ${MENU_OPTION} =~ ^[1-4]$ ]]; do
		read -rp "Select an option [1-4]: " MENU_OPTION
	done
	case "${MENU_OPTION}" in
	1)
		newClient
		;;

	2)
		uninstallWg
		;;
	3)
		exit 0
		;;
	esac
}
# Check for root, virt, OS...
initialCheck
