# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
	config.vm.box		= "ubuntu/trusty64"

	config.vm.provider :virtualbox do |vb|
		vb.customize ["modifyvm", :id, "--memory", 2048, "--cpus", 1]
	end
	
	config.vm.synced_folder "~/.ssh", "/keys"
	config.vm.synced_folder "puppet/files", "/vagrant/files"

	config.puppet_install.puppet_version = "3.8.1"
	config.librarian_puppet.puppetfile_dir = "puppet"
	config.librarian_puppet.placeholder_filename = ".MYPLACEHOLDER"
	config.librarian_puppet.use_v1_api  = '1' # Check https://github.com/rodjek/librarian-puppet#how-to-use
	config.librarian_puppet.destructive = false # Check https://github.com/rodjek/librarian-puppet#how-to-use

	config.vm.provision :puppet do |puppet|
		puppet.options = "--verbose --debug"
		puppet.manifests_path = "puppet/manifests"
		puppet.module_path = "puppet/modules"

		config.vm.define "devhub" do |devhub|
			config.vm.network "forwarded_port", guest: 8080, host: 8080
			# The git server microservice does not support authentication
			# The git server can be exposed from the VM for convenience,
			# but be aware of the security consequences!
			# config.vm.network "forwarded_port", guest: 8081, host: 8081
			puppet.manifest_file = "default.pp"
		end

		config.vm.define "build" do |build|
			config.vm.network "forwarded_port", guest: 8082, host: 8082
			puppet.manifest_file = "build-server.pp"
		end
	end

end
