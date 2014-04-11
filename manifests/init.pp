# == Class: kiosk
#
# Puppet module to install kiosk browser
#
# === Authors
#
# foppe.pieters@naturalis.nl
#
# === Copyright
#
# Copyright 2014
#

class kiosk(
  $packages       = ['xorg','openbox','squid3'],
  $midoridirs     = ['/home/kiosk/.config','/home/kiosk/.config/midori']
)
{

  ensure_resource('file', '/etc/apt/sources.list.d',{
    ensure        => 'directory'
    }
  )
# add midori key
  apt::key { 'ppa:midori':
    key           => 'A69241F1',
    key_server    => 'keyserver.ubuntu.com',
  }
# install latest midori browser
  package { 'midori':
    ensure        => latest,
    require       => Apt::Key['ppa:midori']
  }
# install packages
  package { $packages:
    ensure        => installed
  }
# setup kiosk user
  user { "kiosk":
    comment       => "kiosk user",
    home          => "/home/kiosk",
    ensure        => present,
    managehome    => true,
    password      => sha1('kiosk'),
  }
# startx on login
  file { '/home/kiosk/.profile':
    ensure        => present,
    mode          => '0644',
    content       => template("kiosk/.profile.erb"),
    require       => [User['kiosk']]
  }
# autologin kiosk user
  file { '/etc/init/tty1.conf':
    ensure        => present,
    mode          => '0644',
    content       => template("kiosk/tty1.conf.erb"),
    require       => [User['kiosk']]
  }
# autostart midori in fullscreen
  file { '/home/kiosk/.xinitrc':
    ensure        => present,
    mode          => '0644',
    owner         => 'kiosk',
    content       => '/usr/bin/midori -e Fullscreen',
    require       => [User['kiosk']]
  }
# squid proxy config
  file { '/etc/squid3/squid.conf':
    ensure        => present,
    mode          => '0644',
    content       => template("kiosk/squid.conf.erb"),
    require       => [Package[$packages]]
  }
# ensure squid is running
  service { 'squid3':
    ensure        => 'running',
    require       => File['/etc/squid3/squid.conf']
  }
# make userdirs
  file { $midoridirs:
    ensure        => 'directory',
    require       => User['kiosk'],
    owner         => 'kiosk',
    group         => 'kiosk'
  }
# set midori config
  file { '/home/kiosk/.config/midori/config':
    ensure        => present,
    mode          => '0644',
    content       => template("kiosk/midori-config.erb"),
    require       => [Package['midori'],File[$midoridirs]]
  }

}