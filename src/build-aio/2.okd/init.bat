VBoxmanage import empty.ova 
VBoxmanage modifyvm "empty" --name okd4-aio-bootstrap
VBoxmanage modifyvm "okd4-bootstrap" --macaddress1 080027C5EE79
VBoxmanage modifyvm "okd4-bootstrap" --memory 8092

VBoxmanage import empty.ova
VBoxmanage modifyvm "empty" --name okd4-aio-master
VBoxmanage modifyvm "okd4-master-1" --macaddress1 08002764D665
VBoxmanage modifyvm "okd4-master-1" --memory 16384
