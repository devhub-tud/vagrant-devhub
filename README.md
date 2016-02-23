# vagrant-devhub
Vagrant and Puppet files to provision Devhub servers

## Install
```sh
git clone https://github.com/devhub-tud/vagrant-devhub.git
vagrant plugin install vagrant-librarian-puppet
vagrant up
```

## Login
The default user is `admin` / `admin`, installed as `cn=admin,dc=devhub,dc=local` in openldap.
Through ldapadd additional users can be added.
For more information, see: https://help.ubuntu.com/lts/serverguide/openldap-server.html . 

