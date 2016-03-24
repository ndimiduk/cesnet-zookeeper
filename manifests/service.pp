# Class: zookeeper::service
#
# Launch zookeeper service.
#
class zookeeper::service {

  # HDP packages don't provide service scripts o.O
  file {'/etc/init/zookeeper-server.conf':
    ensure  => file,
    content => template('zookeeper/zookeeper-server.conf.erb'),
    mode    => '0644',
    owner   => root,
    group   => root,
    before  => Service[$zookeeper::daemon],
  }

  service { $zookeeper::daemon:
    ensure => 'running',
    enable => true,
  }
}
