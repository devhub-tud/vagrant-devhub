include jdk_oracle

class { 'maven::maven':
 version => '3.3.9'
}

# include devhub::build-server
include devhub::git-server
include devhub::devhub-server

class devhub::devhub-server {

  include postgresql::server

  postgresql::server::db { 'devhub':
   user     => 'devhub',
   password => postgresql_password('devhub', 'mypassword'),
  }

  user { 'devhub':
   ensure => 'present',
   managehome => true
  }

  file { '/etc/devhub-server':
    ensure => 'directory',
    owner => 'devhub',
    group => 'devhub',
    mode => '755',
    require => User['devhub']
  }

  file { '/etc/devhub-server/config':
    ensure => 'directory',
    owner => 'devhub',
    group => 'devhub',
    mode => '755',
    require => File['/etc/devhub-server']
  }

  file { '/etc/devhub-server/config/config.properties':
    ensure => 'present',
    owner => 'devhub',
    group => 'devhub',
    require => File['/etc/devhub-server/config'],
    source => '/vagrant/files/config/devhub-server.properties'
  }

  file { '/etc/devhub-server/config/persistence.properties':
      ensure => 'present',
      owner => 'devhub',
      group => 'devhub',
      require => File['/etc/devhub-server/config'],
      source => '/vagrant/files/config/devhub-persistence.properties'
    }

  file { '/etc/init.d/devhub-server':
    ensure => 'present',
    owner => 'root',
    group => 'root',
    mode => '755',
    source => '/vagrant/files/services/devhub-server.sh'
  }

  exec { 'deploy devhub-server':
    command => '/usr/sbin/service devhub-server deploy',
    user => 'root',
    require => [
      User['devhub'],
      File['/etc/init.d/devhub-server'],
      File['/etc/devhub-server/config/config.properties'],
      File['/etc/devhub-server/config/persistence.properties'],
      Class['postgresql::server'],
      Class['maven::maven'],
      Class['jdk_oracle']
    ]
  }

  service { 'devhub-server':
    ensure => running,
    require => Exec['deploy devhub-server']
  }
}

class devhub::git-server {

  class { 'gitolite':
   admin_pub_key => file('/keys/id_rsa.pub'),
  }

  package { "git":
    ensure		=> present,
  }

  file { '/etc/git-server':
    ensure => 'directory',
    owner => 'git',
    group => 'git',
    mode => '755',
    require => User['git']
  }

  file { '/srv/git/.ssh/id_rsa':
    owner => 'git',
    group => 'git',
    source => '/keys/id_rsa',
    require => [
      Class['gitolite'],
      User['git']
    ]
  }

  file { '/srv/git/.ssh/id_rsa.pub':
    owner => 'git',
    group => 'git',
    source => '/keys/id_rsa.pub',
    require => [
      Class['gitolite'],
      User['git']
    ]
  }

  file { '/etc/git-server/config':
    ensure => 'directory',
    owner => 'git',
    group => 'git',
    mode => '755',
    require => File['/etc/git-server']
  }

  file { '/etc/git-server/config/config.properties':
    ensure => 'present',
    owner => 'git',
    group => 'git',
    require => File['/etc/git-server/config'],
    source => '/vagrant/files/config/git-server.properties'
  }

  file { '/etc/init.d/git-server':
    ensure => 'present',
    owner => 'root',
    group => 'root',
    mode => '755',
    source => '/vagrant/files/services/git-server.sh'
  }

  exec { 'deploy git-server':
    command => '/usr/sbin/service git-server deploy',
    user => 'root',
    require => [
      User['git'],
      File['/etc/init.d/git-server'],
      File['/etc/git-server/config/config.properties'],
      File['/srv/git/.ssh/id_rsa'],
      Class['maven::maven'],
      Class['jdk_oracle'],
      Class['gitolite']
    ]
  }

  service { 'git-server' :
    ensure => running,
    require => Exec['deploy git-server']
  }

  exec { 'forward port':
    command => '/sbin/iptables -t nat -A OUTPUT -o lo -p tcp --dport 2222 -j REDIRECT --to-port 22',
    user => 'root'
  }

}

class devhub::build-server {

  package { "git":
    ensure		=> present,
  }

  group { 'build' :
    ensure => 'present',
    gid => '1004'
  }

  user { 'build':
    ensure => 'present',
    gid => '1004',
    uid => '1003',
    managehome => true,
    require => Group['build']
  }

  class { 'docker':
    tcp_bind        => '0.0.0.0:4243',
    socket_bind     => 'unix:///var/run/docker.sock'
  }

  file { '/etc/build-server':
    ensure => 'directory',
    owner => 'build',
    group => 'build',
    mode => '755',
    require => User['build']
  }

  file { '/etc/build-server/config':
    ensure => 'directory',
    owner => 'build',
    group => 'build',
    mode => '755',
    require => File['/etc/build-server']
  }

  file { '/etc/build-server/config/config.properties':
    ensure => 'present',
    owner => 'build',
    group => 'build',
    require => File['/etc/build-server/config'],
    source => '/vagrant/files/config/build-server.properties'
  }

   file { '/etc/build-server/workspace':
     ensure => 'directory',
     owner => 'build',
     group => 'build',
     require => File['/etc/build-server']
   }

  file { '/etc/init.d/build-server':
    ensure => 'present',
    owner => 'root',
    group => 'root',
    mode => '755',
    source => '/vagrant/files/services/build-server.sh'
  }

  exec { 'deploy build-server':
    command => '/usr/sbin/service build-server deploy',
    user => 'root',
    require => [
      User['build'],
      File['/etc/init.d/build-server'],
      File['/etc/build-server/workspace'],
      File['/etc/build-server/config/config.properties'],
      Class['docker'],
      Class['maven::maven'],
      Class['jdk_oracle'],
      Package['git']
    ]
  }

  service { 'build-server':
    ensure => running,
    require => Exec['deploy build-server']
  }

  docker::image { 'java-maven':
    ensure      => 'present',
    image_tag   => 'java-maven',
    docker_file => '/vagrant/files/dockerfiles/java-maven/Dockerfile',
  }

}
