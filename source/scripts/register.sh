#! /bin/bash -x

timestamp()
{
 date +"%Y-%m-%d %T"
}

echo "${timestamp}: Registering the system"

source /tmp/secrets.pass
rm /tmp/secrets.pass


subscription-manager register --username ${USERNAME} --password ${PASSWORD}
subscription-manager attach 
# --pool=${POOLID}
subscription-manager repos --enable rhel-7-server-extras-rpms

#  RB 03/09/2019
# Suggested per https://access.redhat.com/solutions/69319 to resolve HTTP 403
subscription-manager refresh

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
# Try new syntax
cat >/etc/sysconfig/network-scripts/ifcfg-eth0 <<EOL
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="no"
PEERDNS="yes"
IPV6INIT="no"
EOL


#  Original non-working script
#echo <<< EOL
#DEVICE="eth0"
#BOOTPROTO="dhcp"
#ONBOOT="yes"
#TYPE="Ethernet"
#USERCTL="no"
#PEERDNS="yes"
#IPV6INIT="no"
#EOL > /etc/sysconfig/network-scripts/ifcfg-eth0

# Remove any persistent network device rules
echo "${timestamp}: Remove any persistent network device rules"
rm -f /etc/udev/rules.d/70-persistent-net.rules
rm -f /etc/udev/rules.d/75-persistent-net-generator.rules

chkconfig network on

systemctl enable sshd
systemctl is-enabled sshd

echo "${timestamp}: Configure GRUB2 for serial console"
# Customise GRUB to user Azure serial console for easier trouble-shooting.
# sed -i...  in-place edit;  replace matching line in file.
# Consider removing crashkernel=auto, probably not needed.
sed -i 's/GRUB_CMDLINE_LINUX.*/GRUB_CMDLINE_LINUX=\"console=ttyS0,115200n8 earlyprintk=ttyS0,115200 rootdelay=300 rd.lvm.lv=rhel\/root\"/g' /etc/default/grub

# Original non-working line.
#sed 's/GRUB_CMD_LINUX.* GRUB_CMD_LINUX="rd.lvm.lv=rhel/root crashkernel=256M earlyprintk=ttyS0 console=ttyS0 rootdelay=300"/g' /etc/default/grub

grub2-mkconfig -o /boot/grub2/grub.cfg

echo "${timestamp}: Deregistering system"
#subscription-manager remove --all
#subscription-manager unregister
subscription-manager clean


echo "${timestamp}:  Configure waagent for swap"
#  Assumes(!) that .EnableSwap & .SwapSizeMB entries exist
sed -i 's/ResourceDisk\.EnableSwap.*/ResourceDisk\.EnableSwap\=y/g' /etc/waagent.conf
sed -i 's/ResourceDisk\.SwapSizeMB.*/ResourceDisk\.SwapSizeMB\=2048/g' /etc/waagent.conf

#  deprovision: Attempt to clean the system and make it suitable for reprovisioning. The following operation deletes:
#     All SSH host keys (if Provisioning.RegenerateSshHostKeyPair is 'y' in the configuration file)
#     Nameserver configuration in /etc/resolv.conf
#     Root password from /etc/shadow (if Provisioning.DeleteRootPassword is 'y' in the configuration file)
#     Cached DHCP client leases
#     Resets host name to localhost.localdomain
waagent -force -deprovision
export HISTSIZE=0


echo "${timestamp}: Complete!"
