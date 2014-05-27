# == Class: kiosk::java
#
# Puppet module to install java modus
#
# === Authors
#
# foppe.pieters@naturalis.nl
#
# === Copyright
#
# Copyright 2014
#

class kiosk::java(
  $packages                             = ['xorg','openbox','openjdk-7-jre','p7zip-full','build-essential'],
  $extractpassword                      = undef,
  $applet_name                          = undef,
  $interactive_name                     = undef,
  $midoridirs                           = ['/home/kiosk/','/home/kiosk/.config','/home/kiosk/.config/midori','/home/kiosk/.config/midori/extensions','/home/kiosk/.config/midori/extensions/libmouse-gestures.so','/home/kiosk/.config/openbox','/home/kiosk/.local/','/home/kiosk/.local/share/','/home/kiosk/.local/share/midori','/home/kiosk/.local/share/midori/styles','/home/kiosk/.icons/','/home/kiosk/.icons/default/','/home/kiosk/.icons/default/cursors']
)
{
  include stdlib
# install packages
  package { $packages:
    ensure        => installed
  }

ensure_resource('file', '/etc/apt/sources.list.d',{
    ensure        => 'directory'
    }
  )
# add midori key
  apt::ppa { 'ppa:midori/ppa':
    require => File['/etc/apt/sources.list.d']
  }
# install latest midori browser
  package { 'midori':
    ensure        => latest,
    require       => Apt::Ppa['ppa:midori/ppa']
  }
# download and untar transparent cursor
  exec { 'download_transparent':
      command        => "/usr/bin/curl http://downloads.yoctoproject.org/releases/matchbox/utils/xcursor-transparent-theme-0.1.1.tar.gz -o /tmp/xcursor-transparent-theme-0.1.1.tar.gz && /bin/tar -xf /tmp/xcursor-transparent-theme-0.1.1.tar.gz -C /tmp",
      unless         => "/usr/bin/test -f /tmp/xcursor-transparent-theme-0.1.1.tar.gz",
      require        => [Package[$packages]]
  }
# configure transparent cursor
  exec {"make_transparent":
    command               => "/bin/sh -c "./configure" && cd cursors && make install-data-local DESTDIR=/home/kiosk/.icons/default CURSOR_DIR=/cursors",
    cwd                   => "/tmp/xcursor-transparent-theme-0.1.1",
    path                  => "usr/bin/",
    unless                => "/usr/bin/test -d /home/kiosk/.icons/default/cursors/transp",
    require               => Exec["download_transparent"]
  }
# autoset transparent cursor
   file { '/home/kiosk/.icons/default/cursors/emptycursor':
    ensure                => present,
    mode                  => '0644',
    content               => template("kiosk/emptycursor.erb"),
    require               => Exec["make_transparent"]
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
# make userdirs
  file { $midoridirs:
    ensure        => 'directory',
    require       => User['kiosk'],
    owner         => 'kiosk',
    group         => 'kiosk',
    mode          => '0644'
  }
# set midori config
  file { '/home/kiosk/.config/midori/config':
    ensure        => present,
    mode          => '0644',
    content       => template("kiosk/midori-config.erb"),
    require       => [Package['midori'],File[$midoridirs]]
  }
# set mouse gestures
  file { '/home/kiosk/.config/midori/extensions/libmouse-gestures.so/config':
    ensure        => present,
    mode          => '0644',
    content       => template("kiosk/mousegestures-config.erb"),
    require       => [Package['midori'],File[$midoridirs]],
    owner         => 'kiosk',
    group         => 'kiosk'
  }
# set mouse gestures 2
  file { '/home/kiosk/.config/midori/extensions/libmouse-gestures.so/gestures':
    ensure        => present,
    mode          => '0644',
    content       => template("kiosk/mousegestures-gestures.erb"),
    require       => [Package['midori'],File[$midoridirs]],
    owner         => 'kiosk',
    group         => 'kiosk'
  }
# improve scrollbar
  file { '/home/kiosk/.gtkrc-2.0':
    ensure        => present,
    mode          => '0644',
    content       => template("kiosk/.gtkrc-2.0.erb"),
    require       => [Package['midori'],File[$midoridirs]]
  }
# autostart midori
    file { '/home/kiosk/.config/openbox/autostart.sh':
    ensure        => present,
    mode          => '0644',
    content       => template("kiosk/openbox-autostart-java.sh.erb"),
    require       => [File['/home/kiosk/.config/openbox']]
    }

common::directory_structure{ "/data/kiosk/${applet_name}":
  user            => 'kiosk',
  mode            => '0755'
}
# download java applet
  file {"/data/kiosk/${applet_name}/${applet_name}.zip":
    source        => "puppet:///modules/kiosk/${applet_name}.zip",
    ensure        => "present",
    mode          => "755",
    owner         => "kiosk",
    group         => "kiosk",
    require       => Common::Directory_structure["/data/kiosk/${applet_name}"]
  }
# unzip java applet
  exec {"unzip":
    command       => "/usr/bin/7z x -p${extractpassword} -aoa /data/kiosk/${applet_name}/${applet_name}.zip",
    cwd           => "/data/kiosk/${applet_name}",
    unless        => "/usr/bin/test -f /data/kiosk/${applet_name}/data",
    require       => Common::Directory_structure["/data/kiosk/${applet_name}"]
  }

}
