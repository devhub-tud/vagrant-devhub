include devhub::build-server

class devhub::build-server {

  include jdk_oracle

  class { 'maven::maven':
   version => '3.3.9'
  }

  group { 'build' :
   ensure => 'present',
   gid => '1004'
  }

  user { 'build':
   ensure => 'present',
   gid => '1004',
   uid => '1003',
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

  file { '/etc/build-server/config/config.properties':
    ensure => 'present',
    owner => 'build',
    group => 'build',
    require => [
      User['build'],
      File['/etc/build-server']
    ],
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

  service { 'build-server' :
    ensure => 'running',
    enable => 'true',
    start => 'deploy',
    require => [
      User['build'],
      File['/etc/init.d/build-server'],
      File['/etc/build-server/workspace'],
      File['/etc/build-server/config/config.properties'],
      Class['docker']
    ]
  }

  docker::image { 'java-maven':
    ensure      => 'present',
    image_tag   => 'java-maven',
    docker_file => '/vagrant/files/dockerfiles/java-maven/Dockerfile',
  }

}


#class { 'postgresql::server': }
#
#postgresql::server::db { 'devhub':
#  user     => 'devhub',
#  password => postgresql_password('devhub', 'mypassword'),
#}
#
#class { 'gitolite':
#  admin_pub_key => file('/keys/id_rsa.pub'),
#}
