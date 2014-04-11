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
  $midoridirs     = ['/home/kiosk/.config','/home/kiosk/.config/midori','/home/kiosk/.config/openbox','/home/kiosk/.local/share/midori','/home/kiosk/.local/share/midori/styles'],
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
# autostart openbox and disable screensaver/blanking
  file { '/home/kiosk/.xinitrc':
    ensure        => present,
    mode          => '0644',
    owner         => 'kiosk',
    content       => template("kiosk/.xinitrc.erb"),
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
# autostart midori
  file { '/home/kiosk/.config/openbox/autostart.sh':
    ensure        => present,
    mode          => '0644',
    content       => template("kiosk/openbox-autostart.sh.erb"),
    require       => [Package['midori'],File[$midoridirs]]
  }
# improve midori scrollbar
  file { '/home/kiosk/.gtkrc-2.0':
    ensure        => present,
    mode          => '0644',
    content       => template("kiosk/.gtkrc-2.0.erb"),
    require       => [Package['midori'],File[$midoridirs]]
  }
# improve midori scrollbar more
  file { '/home/kiosk/.local/share/midori/styles/scrollbar.user.css':
    ensure        => present,
    mode          => '0644',
    owner         => 'kiosk',
    group         => 'kiosk',
    content       => template("kiosk/scrollbar.user.css.erb"),
    require       => [Package['midori'],File[$midoridirs]]
  }
}