include jdk_oracle

class { 'maven::maven':
 version => '3.3.9'
}

include devhub::build-server

class devhub::build-server {

  package { 'git':
    ensure		=> present,
  }

  group { 'build':
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

  file { '/etc/docker':
    ensure => 'directory'
  }

  file { '/etc/docker/tls':
    ensure => 'directory',
    require => File['/etc/docker']
  }

  file { '/etc/docker/tls/setup_keys.sh':
    ensure => 'present',
    source => '/vagrant/files/scripts/setup_keys.sh',
    mode => '744',
    require => File['/etc/docker/tls']
  }

  exec { 'ssh_keys':
    command => '/etc/docker/tls/setup_keys.sh',
    cwd => '/etc/docker/tls',
    creates => '/etc/docker/tls/server-cert.pem',
    require => File['/etc/docker/tls/setup_keys.sh'],
    user => root,
    logoutput => true
  }

  class { 'docker':
    tcp_bind        => ['tcp://0.0.0.0:2376'],
    tls_enable      => true,
    tls_cacert      => '/etc/docker/tls/ca.pem',
    tls_cert        => '/etc/docker/tls/server-cert.pem',
    tls_key         => '/etc/docker/tls/server-key.pem',
    socket_bind     => 'unix:///var/run/docker.sock',
    require         => Exec['ssh_keys']
  }

  file { '/home/build/.docker':
    ensure => 'directory',
    owner => 'build',
    group => 'build',
    mode => '755',
    require => User['build']
  }

  file { '/home/build/.docker/ca.pem':
    ensure => 'present',
    source => '/etc/docker/tls/ca.pem',
    owner => 'build',
    group => 'build',
    mode => '444',
    require => [Exec['ssh_keys'], User['build']]
  }

  file { '/home/build/.docker/cert.pem':
    ensure => 'present',
    source => '/etc/docker/tls/cert.pem',
    owner => 'build',
    group => 'build',
    mode => '444',
    require => [Exec['ssh_keys'], User['build']]
  }

  file { '/home/build/.docker/key.pem':
    ensure => 'present',
    source => '/etc/docker/tls/key.pem',
    owner => 'build',
    group => 'build',
    mode => '444',
    require => [Exec['ssh_keys'], User['build']]
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
    require => [
      File['/home/build/.docker/ca.pem'],
      File['/home/build/.docker/cert.pem'],
      File['/home/build/.docker/key.pem'],
      Exec['deploy build-server']
    ]
  }

  docker::image { 'java-maven':
    ensure      => 'present',
    docker_file => '/vagrant/files/dockerfiles/java-maven/Dockerfile',
  }

}
