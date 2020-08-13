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

# Configure dhcp server
sudo yum install -y dhcp
 
sudo cp dhcpd.conf /etc/dhcp/

sudo systemctl enable dhcpd
sudo systemctl restart dhcpd

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

#######################################################
# Final set-up
#######################################################
# Once the cluster is up & running, you still need to 
# do few things :
#   1. Accept all certificates which are pending
#         oc get csr -ojson | jq -r '.items[] | select(.status == {} ) | .metadata.name' | xargs oc adm certificate approve
#   2. Create the PV for the registry
#         oc create -f registry_pv.yaml
#   3. Update the Image Registry PVC to use that new PV
#         oc edit configs.imageregistry.operator.openshift.io
#         	spec:
#         	  ...
#         	  managementState: Managed
#         	  ...
#         	  storage:
#         	    pvc:
#         	      claim:
#         	status:
#         	  ...
#   4. Wait for all clusteroperators to be up & runnning (may take some time...)
#   5. Update your /etc/host on your desktop to point to the services VM:
#   		10.0.0.10 console-openshift-console.apps.cluster.okd4.local oauth-openshift.apps.cluster.okd4.local
#######################################################