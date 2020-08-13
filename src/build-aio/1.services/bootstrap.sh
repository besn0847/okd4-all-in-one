#!/bin/sh

cd bootstrap

# Update vagrant user pub key
cp authorized_keys /home/vagrant/.ssh/authorized_keys
chown vagrant.vagrant /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
echo "KUBECONFIG=/home/vagrant/bootstrap/install_dir/auth/kubeconfig; export KUBECONFIG" >> /home/vagrant/.bash_profile

# Install Openshift clients
tar xvfz openshift-client-linux-4.5.0-0.okd-2020-06-29-110348-beta6.tar.gz
tar xvfz openshift-install-linux-4.5.0-0.okd-2020-06-29-110348-beta6.tar.gz

mv oc /usr/local/bin
mv kubectl /usr/local/bin
mv openshift-install /usr/local/bin

# Configure DNS service
sudo yum -y install bind bind-utils
sudo cp named.conf /etc/named.conf
sudo cp named.conf.local /etc/named/
sudo mkdir /etc/named/zones
sudo cp db* /etc/named/zones

sudo systemctl enable named
sudo systemctl start named
sudo systemctl status named

nmcli con mod "System eth0" ipv4.ignore-auto-dns yes
nmcli con mod "System eth1" ipv4.dns "10.0.0.10 8.8.8.8 8.8.4.4"
nmcli con mod "System eth1" ipv4.dns-search "okd4.local, cluster.okd4.local"
nmcli con down "System eth0"
nmcli con down "System eth1"
nmcli con up "System eth0"
nmcli con up "System eth1"

# Configure HAproxy service
sudo yum install -y haproxy

sudo cp haproxy.cfg /etc/haproxy/haproxy.cfg

sudo setsebool -P haproxy_connect_any 1
sudo systemctl enable haproxy
sudo systemctl start haproxy
sudo systemctl status haproxy

# Configure HTTP service
sudo yum install -y httpd

sudo cp httpd.conf /etc/httpd/conf/httpd.conf

sudo setsebool -P httpd_read_user_content 1
sudo systemctl enable httpd
sudo systemctl start httpd

# Set-up Openshift ignition directory
sudo mkdir install_dir

sudo cp install-config.yaml ./install_dir
sudo /usr/local/bin/openshift-install create manifests --dir=install_dir/
sudo /usr/local/bin/openshift-install create ignition-configs --dir=install_dir/

sudo mkdir /var/www/html/okd4
sudo cp -R install_dir/* /var/www/html/okd4/
sudo chown -R apache: /var/www/html/
sudo chmod -R 755 /var/www/html/

sudo systemctl start httpd

# Configure boot for bootstrao, masters & workers
sudo yum install -y dhcp
 
sudo cp dhcpd.conf /etc/dhcp/

sudo systemctl enable dhcpd
sudo systemctl restart dhcpd

# Configure PXE boot
sudo yum install -y tftp tftp-server syslinux xinetd

sudo cp -f tftp /etc/xinetd.d/

sudo cp -v /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot
sudo cp -v /usr/share/syslinux/menu.c32 /var/lib/tftpboot
sudo cp -v /usr/share/syslinux/memdisk /var/lib/tftpboot
sudo cp -v /usr/share/syslinux/mboot.c32 /var/lib/tftpboot

sudo mkdir /var/lib/tftpboot/pxelinux.cfg
sudo mkdir -p /var/lib/tftpboot/bootstrap/pxelinux.cfg
sudo mkdir -p /var/lib/tftpboot/master/pxelinux.cfg
sudo mkdir -p /var/lib/tftpboot/worker/pxelinux.cfg
sudo mkdir /var/www/html/okd4/pxeboot

sudo cp -v /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/bootstrap/
sudo cp -v /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/master/
sudo cp -v /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/worker/

sudo cp -f default /var/lib/tftpboot/pxelinux.cfg/
sudo cp -f bootstrap /var/lib/tftpboot/bootstrap/pxelinux.cfg/default
sudo cp -f master /var/lib/tftpboot/master/pxelinux.cfg/default
sudo cp -f worker /var/lib/tftpboot/worker/pxelinux.cfg/default


sudo cp fedora-coreos-32.20200615.3.0-metal.x86_64.raw.xz /var/www/html/okd4/pxeboot/fcos.raw.xz
sudo cp fedora-coreos-32.20200615.3.0-metal.x86_64.raw.xz.sig /var/www/html/okd4/pxeboot/fcos.raw.xz.sig
sudo cp fedora-coreos-32.20200615.3.0-live-initramfs.x86_64.img /var/www/html/okd4/pxeboot/initramfs.img
sudo cp fedora-coreos-32.20200615.3.0-live-kernel-x86_64 /var/www/html/okd4/pxeboot/vmlinuz

sudo chown -R apache: /var/www/html/
sudo chmod -R 755 /var/www/html/

sudo systemctl enable xinetd

sudo systemctl restart httpd
sudo systemctl restart dhcpd
sudo systemctl restart xinetd

# Install certificate tool
sudo yum install -y wget net-tools
sudo wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
sudo chmod +x jq
sudo mv jq /usr/local/bin/

# Install nfs share
sudo yum install –y nfs-utils
sudo mkdir /var/nfsshare
sudo mkdir /var/nfsshare/registry
sudo chmod -R 777 /var/nfsshare
sudo hown -R nfsnobody:nfsnobody /var/nfsshare
sudo mv /var/nfsshare/ /home/vagrant/
sudo ln -s /home/vagrant/nfsshare/ /var/nfsshare
sudo echo "/var/nfsshare 10.0.0.0/24(rw,sync,no_root_squash,no_all_squash,no_wdelay)" > /etc/exports
sudo setsebool -P nfs_export_all_rw 1
sudo systemctl restart nfs-server

# Use this node as router for the whole OKD deployment
sudo systemctl disable firewalld
sudo systemctl mask --now firewalld

sudo echo 1 > /proc/sys/net/ipv4/ip_forward
sudo echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

sudo iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
sudo iptables --append FORWARD --in-interface eth1 -j ACCEPT

sudo yum install -y iptables-services
sudo iptables-save > /etc/sysconfig/iptables
sudo systemctl enable iptables
sudo /usr/libexec/iptables/iptables.init save
