Vagrant.configure("2") do |aio|
  aio.ssh.insert_key = false

  aio.vm.define "services" do |services|
    services.vm.box = "okd4-aio-services"
    services.vm.hostname = 'services'

    services.vm.synced_folder ".", "/vagrant", disabled: true

    services.vm.network :private_network, ip: "10.0.0.10"

    services.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 1024]
      v.customize ["modifyvm", :id, "--name", "okd4-aio-services"]
    end
  end

  aio.vm.define "master" do |master|
    master.vm.box = "okd4-aio-master"
    master.vm.hostname = 'master'

    master.vm.synced_folder ".", "/vagrant", disabled: true

    master.vm.network :private_network, ip: "10.0.0.11"

    master.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 16384]
      v.customize ["modifyvm", :id, "--name", "okd4-aio-master"]
    end
  end
end


