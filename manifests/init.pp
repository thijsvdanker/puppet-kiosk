# == Class: kiosk
#
# Full description of class kiosk here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { kiosk:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name foppe.pieters@naturalis.nl
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#

class kiosk ()

{

exec { 'apt-update':
  command => 'apt-get update',
  path    => '/bin:/usr/bin',
  timeout => 0
}

apt::ppa { 'ppa:midori/ppa':
  before => Exec['apt-update']
}

package { [
  'xorg',
  'openbox',
  'midori',
  'squid3'
  ]:
  ensure  => present,
  require => Exec['apt-update']
}

file { '/home/kiosk/.profile':
    ensure  => present,
    mode    => '0644',
    content => template("kiosk/.profile.erb"),
    require => Package['openbox']
  }

file { '/etc/squid3/squid.conf':
    ensure  => present,
    mode    => '0644',
    content => template("kiosk/squid.conf.erb"),
    require => Package['squid3']

}

file { '/home/kiosk/.config/midori/config':
    ensure  => present,
    mode    => '0644',
    content => template("kiosk/config.erb"),
    require => Package['midori']

}

 service { 'squid3':
    ensure  => 'running',
    require => File['/etc/squid3/squid.conf']
  }

}

