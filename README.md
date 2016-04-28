# vagrant-devhub
Vagrant and Puppet files to provision DevHub servers.

The project consists of a Vagrant Multi-Machine configuration, consisting of two parts:
* A DevHub server with an internal Git API microservice backed by Gitolite;
* A Build server with a Docker host which can be used for enabling Continuous Integration for DevHub.

*Both machines share your `~/.ssh` key folder.
This key is used as administrator key for the Gitolite installation.
Furthermore, the build server uses your public key to have read access on the repositories.
Your local SSH key essentially becomes the master key for Devhub.
If you want to use another SSH key for the machines, modify the `/keys` folder sharing in the Vagrant file.*

## Install
Ensure that you have [Vagrant](https://www.vagrantup.com) installed on your local system.
Vagrant also needs a virtualization platform to run on. We recommend to install [VirtualBox](https://www.virtualbox.org) with Vagrant.
We use `vagrant-librarian-puppet` in order to download the required Puppet libraries.
The commands listed below assume you have not installed `vagrant-librarian-puppet` yet.

```sh
git clone https://github.com/devhub-tud/vagrant-devhub.git
vagrant plugin install vagrant-librarian-puppet
vagrant up
```

As this project is set up as a Multi-Machine project, `vagrant up` provisions both the DevHub server and a build server.
You can provision these servers individually as well, using the following commands:

```sh
vagrant up devhub
vagrant up build
```

### Bare server provisioning
The Puppet scripts can also be used to deploy a bare server.
You need `puppet` and `librarian-puppet` for this.

```
sudo apt-get install -y virtualbox vagrant rubygems ruby build-essential puppet
gem install librarian-puppet
git clone https://github.com/devhub-tud/vagrant-devhub.git
cd vagrant-devhub
librarian-puppet install
puppet apply --modulepath puppet/modules puppet/manifests/default.pp --verbose --debug
```

## Login to Devhub
The administrator user is `admin` / `admin`, installed as `cn=admin,dc=devhub,dc=local` in openldap.
This user can be used to log in to DevHub, but also to add new users to the DevHub instance.

### Adding new users
Through `ldapadd` additional users can be added.

In order to do so, first create an `.ldiff` file, containing the changes for the LDAP directory.
First, ensure that the Base DN is created.

```
dn: dc=devhub,dc=local
objectClass: top
objectClass: dcObject
objectClass: organization
dc: devhub
o: Devhub
```

In the next step, we add a user to our `.ldiff` file:

```
dn: uid=jgmeligmeyling,dc=devhub,dc=local
cn: Jan-Willem Gmelig Meyling
givenName: Jan-Willem
sn: Gmelig Meyling
uid: jgmeligmeyling
mail: j.gmeligmeyling@student.tudelft.nl
objectClass: top
objectClass: shadowAccount
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
userPassword: password
```

Login to the DevHub VM and execute the following commands.

```sh
vagrant ssh devhub # SSH into the Devhub VM
sudo apt-get -y install ldap-utils # install LDAP utils
ldapadd -cxWD cn=admin,dc=devhub,dc=local -f input.ldiff
```

For more information, see: https://help.ubuntu.com/lts/serverguide/openldap-server.html .

### Using another directory server
It is possible to connect DevHub to an external LDAP directory, such as Active Directory.
The parameters which DevHub uses to connect to the LDAP server are defined in `devhub-server.properties`.
