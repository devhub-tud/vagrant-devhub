# vagrant-devhub
Vagrant and Puppet files to provision Devhub servers.

The project consists of a Vagrant Multi-Machine configuration, consisting of two parts:
* A Devhub server with an internal Git-server backed by Gitolite;
* A Build server with a Docker host which can be used for enabling Continuous Integration for Devhub.

*Both machines share your `~/.ssh` key folder.
This key is used as administrator key for the Gitolite installation.
Furthermore, the build server uses your public key to have read access on the repositories.
Your local SSH key essentially becomes the master key for Devhub.
If you want to use another SSH key for the machines, modify the `/keys` folder sharing in the Vagrant file.*

## Install
Ensure that you have [Vagrant](https://www.vagrantup.com) installed on your local system.
Vagrant also needs a virtualisation platform to run on. We recommend to install [VirtualBox](https://www.virtualbox.org) with Vagrant.
We use `vagrant-librarian-puppet` in order to download the required Puppet libraries.
The commands listed below assume you have not installed `vagrant-librarian-puppet` yet.

```sh
git clone https://github.com/devhub-tud/vagrant-devhub.git
vagrant plugin install vagrant-librarian-puppet
vagrant up
```

As this project is set up as a Multi-Machine project, `vagrant up` provisions both the Devhub server and a build server.
You can provision these servers individually as well, using the following commands:

```sh
vagrant up devhub
vagrant up build
```

## Login to Devhub
The default user is `admin` / `admin`, installed as `cn=admin,dc=devhub,dc=local` in openldap.
Through `ldapadd` additional users can be added.
For more information, see: https://help.ubuntu.com/lts/serverguide/openldap-server.html .
