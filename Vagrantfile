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

#	config.vm.synced_folder "/etc/git-server/mirrors", "/home/git/mirrors",
#		mount_options: ["dmode=777", "fmode=666"]
#	config.vm.synced_folder "/etc/git-server/repositories", "/home/git/repositories",
#		mount_options: ["dmode=777", "fmode=666"]

	config.puppet_install.puppet_version = "3.8.1"
	config.librarian_puppet.puppetfile_dir = "puppet"
	config.librarian_puppet.placeholder_filename = ".MYPLACEHOLDER"
	config.librarian_puppet.use_v1_api  = '1' # Check https://github.com/rodjek/librarian-puppet#how-to-use
	config.librarian_puppet.destructive = false # Check https://github.com/rodjek/librarian-puppet#how-to-use


	config.vm.provision :puppet do |puppet|
		puppet.options = "--verbose --debug"
		puppet.manifests_path = "puppet/manifests"
		puppet.module_path = "puppet/modules"
	end

end
