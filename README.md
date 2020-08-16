# Origin Kubernetes Distribution 4 : All-in-One
OKD is the upstream version of the well kown Container platform, Openshift. The current version is 4.5. This Github page is designed to help in deploying OKD on a single VM (actually 2 with the Services light one) whereas a normal set-up will take at least 5 VMs (3 masters and 2 workers) making it impossible to run on a normal laptop.

## Content
There are 3 main levels in this repository :
 - **Easy Level** : Simply download the 2 virtual appliances for VirtualBox and get started
 - **Medium Level** : Rebuild your OKD4 Services virtual machine to fine tune DNS, DHCP, NFS...
 - **Advanced Level** : Fully rebuild the 2 virtual machine from scratch
This README page focuses on the first one, for the others, please dive into the "src" directory.

## Pre-requisites
OKD4 is a very hungry beast with more than 75 PODs just to run the Openshift infrastructure requiring around 10 GB RAM and 2 core at mimimum. It also downloads tons of samples needing more than 20 GB of disk. Hence the minimal requirements are quite significant.

You will need at least :
 - 4 cores dedicated to the VMs so your desktop needs at least 6 or 8 cores
 - 16 GB RAM (0.5 for the services VM and the rest for the master VM)
 - 100 GB disk (half for the services VM and the other hald for the master)

The minimal set-up i chose here is in total 5 cores + 17 GB RAM + 200 GB disk. Also make sure you use an SSD drive, an HDD is very very slow.

## Up & Running
There are 5 steps to complete in order to have a fully up and running OKD all-in-one system. Depending on your desktop or laptop, the start-up takes between 5 and 10 minutes. Everything is detailed in the [PDF doc](https://github.com/besn0847/okd4-all-in-one/raw/master/docs/aio.pdf) located in the docs/ directory.

### Step 1 : Clone the git repo for All-In-One
Even though not necessary as you can just download the OVF files from the boxes/ directory, just clone this repo to have all the files on your laptop :
```bash
git clone https://github.com/besn0847/okd4-all-in-one.git
```

### Step 2 : Download the 2 VMDKs
There are 2 large files to download from the web for almost 10 GB in total. Download them in the boxes/directory
| Filename       | Size | SHA256 Hash                         
|--------------------------------|-------------------------------|--------------------
| [okd4-aio-services-disk001.vmdk](https://drive.google.com/file/d/1onY2Z-RjvtVdFx9bEabZho6VNaKmsbdf/view) | 0.7 GB | A3ECB4DC431DB3D6F26C3C0CA3A485096B3D0DE97BDA5C5C84268240D9D7948B
| [okd4-aio-master-disk001.vmdk](https://drive.google.com/file/d/1ni3_eLEamxb5FQFR_e1oZ1KFHVXbK2cs/view) | 8.8 GB | F910B0AEF95DAE5638B5D6427FE6F67B577FD7439D0720B0CC44FAF6D2D4472F

### Step 3 : Import the VMs in VirtualBox
Just import the 2 virtual appliances to VirtualBox and adjust the CPU and RAM if you just have the minimal requirements described above.
**MAKE SURE** you set the MAC address for the OKD4 Master VM to 08:00:27:64:D6:65, otherwise the VM won't pick up its IP address.
Start the 2 VMs.

### Step 4 : Update your /etc/hosts file
Unless you want to add the DNS server running on the OKD4 Services VM to your configuration, you can simply edit your /etc/host (or c:\Windows\system32...) file and add the following entry :
> 10.0.0.10 console-openshift-console.apps.cluster.okd4.local oauth-openshift.apps.cluster.okd4.local

This is suitable for a minimal usage but you will need to update your DNS configuration to levegare the OKD routing native feature.

### Step 5 : Monitor the start-up process and connect to the console
Then just wait for the start-up to complete (~10 minutes). The easiest way to monitor it is to connect through SSH to the OKD4 Services VM (use the 'vagrant' user + the private key located [here](https://github.com/besn0847/okd4-all-in-one/blob/master/src/run-aio/bootstrap/id_rsa)) .

The '*oc get clusteroperators*' and '*oc get pods --all-namespaces*' will give you a good overview of the start-up process. On my set-up, the limitation was primarily on the disk (hence use SSD).
Once the start-up is completed, just connect to the console URL from your laptop :
> URL : [https://console-openshift-console.apps.cluster.okd4.local/](https://console-openshift-console.apps.cluster.okd4.local/)
> Login : kubeadmin
> Password : bRsda-FuxkE-pXAAt-SDEtt

## Tributes

 - Craig Robinson : "[Guide: Installing an OKD 4.5 Cluster](https://itnext.io/guide-installing-an-okd-4-5-cluster-508a2631cbee)"
 - OKD Community : "[OKD: The Origin Community Distribution of Kubernetes](https://github.com/openshift/okd)"
