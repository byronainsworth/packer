#! /bin/bash -x

timestamp()
{
 date +"%Y-%m-%d %T"
}

echo "${timestamp}: Registering the system"

source ./secrets.pass

subscription-manager register --username ${USERNAME} --password ${PASSWORD}
subscription-manager attach --pool=${POOLID}
subscription-manager repos --enable rhel-7-server-extras-rpms


yum -y install WALinuxAgent
systemctl enable waagent.service

echo "${timestamp}: Updating system"
yum update -y


# Custom Azure configuration
echo "${timestamp}: Installing Hyper-V device drivers for RHEL VM"
echo 'add_drivers+=" hv_vmbus "' > /etc/dracut.conf
echo 'add_drivers+=" hv_netvsc "' > /etc/dracut.conf
echo 'add_drivers+=" hv_storvsc "' > /etc/dracut.conf

dracut -f -v --regenerate-all
echo "${timestamp}: Verifying device drivers loaded successfully"
lsinitrd | grep hv

# Enable SSH Password Authentication
echo "${timestamp}: Enable SSH Password Authentication"
sed 's/PasswordAuthentication.* /PasswordAuthentication Yes/g' /etc/ssh/sshd_config

# Configure hostname
echo "${timestamp}: Configure hostname"
hostnamectl set-hostname rhel76.localdomain

# Configure networking
echo "${timestamp}: Configure networking"
echo <<< EOL
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="no"
PEERDNS="yes"
IPV6INIT="no"
EOL > /etc/sysconfig/network-scripts/ifcfg-eth0

# Remove any persistent network device rules
echo "${timestamp}: Remove any persistent network device rules"
rm -f /etc/udev/rules.d/70-persistent-net.rules
rm -f /etc/udev/rules.d/75-persistent-net-generator.rules

chkconfig network on

systemctl enable sshd
systemctl is-enabled sshd


sed 's/GRUB_CMD_LINUX.* GRUB_CMD_LINUX="rd.lvm.lv=rhel/root crashkernel=256M earlyprintk=ttyS0 console=ttyS0 rootdelay=300"/g' /etc/default/grub

grub2-mkconfig -o /boot/grub2/grub.cfg

echo "${timestamp}: Deregistering system"
#subscription-manager remove --all
#subscription-manager unregister
subscription-manager clean

echo "${timestamp}: Complete!"
