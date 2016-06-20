# == Class: zookeeper::config
#
# Zookeeper configuration.
#
class zookeeper::config {
  if $zookeeper::hostnames {
    $myid = array_search($zookeeper::hostnames, $::fqdn)
  } else {
    $myid = undef
  }
  notice("myid: ${myid}")

  if !$myid or $myid == 0 {
    notice("Missing myid! Zookeeper server ${::fqdn} not in zookeeper::hostnames list.")
  }

  file { "${zookeeper::confdir}/zoo.cfg":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('zookeeper/zoo.cfg.erb'),
    alias   => 'zoo-cfg',
  }

  file { "${zookeeper::confdir}/zookeeper-env.sh":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('zookeeper/zookeeper-env.sh.erb'),
    alias   => 'zookeeper-env.sh',
  }

  file { $zookeeper::logdir:
    ensure => directory,
    owner  => 'zookeeper',
    group  => 'zookeeper',
    mode   => '0755',
  }

  file { $zookeeper::piddir:
    ensure => directory,
    owner  => 'zookeeper',
    group  => 'zookeeper',
    mode   => '0755',
  }

  file { $zookeeper::datadir:
    ensure => directory,
    owner  => 'zookeeper',
    group  => 'zookeeper',
    mode   => '0755',
  }

  $keytab = '/etc/security/keytab/zookeeper.service.keytab'
  $principal = "zookeeper/${::fqdn}@${zookeeper::realm}"

  if $zookeeper::realm and $zookeeper::realm!= '' {
    file { $keytab:
      owner => 'zookeeper',
      group => 'zookeeper',
      mode  => '0400',
    }

    file { "${zookeeper::confdir}/jaas.conf":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('zookeeper/jaas.conf.erb'),
    }
  } else {
    file { "${zookeeper::confdir}/jaas.conf":
      ensure => 'absent',
    }
  }

  if $zookeeper::_properties {
    file { "${zookeeper::confdir}/java.env":
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('zookeeper/java.env.erb'),
    }
  } else {
    file { "${zookeeper::confdir}/java.env":
      ensure => 'absent',
    }
  }

  if $myid and $myid != 0 {
    file { "${zookeeper::datadir}/myid":
      owner   => 'zookeeper',
      group   => 'zookeeper',
      mode    => '0644',
      replace => false,
      # lint:ignore:only_variable_string
      # (needed to convert integer to string)
      content => "${myid}",
      # lint:endignore
    }
  }

  case "${::osfamily}-${::operatingsystem}" {
    /RedHat-Fedora/,default: {
      # pass
    }
    /Debian|RedHat/: {
      if $myid and $myid != 0 {
        $args = "--myid ${myid}"
      } else {
        $args = ''
      }
      exec { 'zookeeper-init':
        command => "zookeeper-server-initialize ${args}",
        creates => "${zookeeper::datadir}/version-2",
        path    => '/sbin:/usr/sbin:/bin:/usr/bin:/usr/hdp/current/zookeeper-server/bin',
        user    => 'zookeeper',
        require => [ File['zoo-cfg'], ],
      }
      if $zookeeper::realm and $zookeeper::realm != '' {
        File[$keytab] -> Exec['zookeeper-init']
        File["${zookeeper::confdir}/jaas.conf"] -> Exec['zookeeper-init']
        File["${zookeeper::confdir}/java.env"] -> Exec['zookeeper-init']
      }
    }
  }
}
