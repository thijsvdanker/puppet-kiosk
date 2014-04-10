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
# Copyright 2014
#

class kiosk(
  $packages         = ['xorg','openbox','squid3']
) {

# werkt nog niet
  file { '/etc/apt/sources.list.d':
    ensure => 'directory',
  }

# apt::ppa { 'ppa:midori/ppa':
#  require => File['/etc/apt/sources.list.d']
# }

#   package { 'midori':
#    ensure => installed,
#    require => Apt::Ppa['ppa:midori/ppa']
#  }

   package { $packages:
    ensure      => installed
    }

user { "kiosk":
	comment		=> "kiosk user",
	home		=> "/home/kiosk",
	ensure		=> present,
	managehome	=> true,
	#shell		=> "/bin/bash",
	#uid		=> '501',
	#gid		=> '20'
}
file { '/home/kiosk/.profile':
    ensure		=> present,
    mode		=> '0644',
    content		=> template("kiosk/.profile.erb"),
    require     => [User['kiosk']]
    }

# autologin kiosk user
#   file { '/etc/init/tty1.conf':
#    ensure		=> present,
#    mode		=> '0644',
#    content	=> 'exec /sbin/getty -8 38400 --autologin kiosk tty1',
#    require	=> [User['kiosk']]
#    }

#  autostart midori in kiosk mode
#   file { '/home/kiosk/.xinitrc':
#    ensure		=> present,
#    mode		=> '0644',
#    owner		=> 'kiosk',
#    content	=> '/usr/bin/midori -e Fullscreen -a http://www.naturalis.nl',
#    require	=> [User['kiosk']]
#    }

file { '/etc/squid3/squid.conf':
    ensure		=> present,
    mode		=> '0644',
    content		=> template("kiosk/squid.conf.erb"),
    require     => [Package[$packages]]
 }

 service { 'squid3':
    ensure		=> 'running',
    require		=> File['/etc/squid3/squid.conf']
  }

#file { '/home/kiosk/.config/midori/config':
#    ensure		=> present,
#    mode		=> '0644',
#    content	=> template("kiosk/midori-config.erb"),
#    require	=> Package['midori']
# }


}