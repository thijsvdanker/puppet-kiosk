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
  $dirs                                 = ['/home/kiosk/','/home/kiosk/.config','/home/kiosk/.config/google-chrome','/home/kiosk/.config/google-chrome/Default','/home/kiosk/.config/google-chrome/Default/Extensions','/home/kiosk/.config/openbox','/home/kiosk/.icons/','/home/kiosk/.icons/default/','/home/kiosk/.icons/default/cursors'],
)
{
  include stdlib
 # install packages
   package { $packages:
     ensure                => installed
   }
 ensure_resource('file', '/etc/apt/sources.list.d',{
     ensure                => 'directory'
     }
   )
 # install google-chrome
   file { "/etc/apt/sources.list.d/google.list":
     owner                 => "kiosk",
     group                 => "kiosk",
     mode                  => 444,
     content               => "deb http://dl.google.com/linux/deb/ stable main",
     notify                => Exec["Google apt-key"],
   }
 # Add Google's apt-key.
   exec { "Google apt-key":
     command               => "/usr/bin/wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | /usr/bin/apt-key add -",
     refreshonly           => true,
     notify                => Exec["apt-get update"],
   }
 # refresh:
   exec { "apt-get update":
     command               => "/usr/bin/apt-get update",
     refreshonly           => true,
   }
 # Install latest stable
   package { "google-chrome-stable":
     ensure                => latest,
     require               => [ Exec["apt-get update"]],
   }
 # download and untar transparent cursor
   exec { 'download_transparent':
     command               => "/usr/bin/curl http://downloads.yoctoproject.org/releases/matchbox/utils/xcursor-transparent-theme-0.1.1.tar.gz -o /tmp/xcursor-transparent-theme-0.1.1.tar.gz && /bin/tar -xf /tmp/xcursor-transparent-theme-0.1.1.tar.gz -C /tmp",
     unless                => "/usr/bin/test -f /tmp/xcursor-transparent-theme-0.1.1.tar.gz",
     require               => [Package[$packages]]
   }
 # configure transparent cursor
   exec {"config_transparent":
     command               => "/bin/sh configure",
     cwd                   => "/tmp/xcursor-transparent-theme-0.1.1",
     unless                => "/usr/bin/test -f /home/kiosk/.icons/default/cursors/transp",
     require               => Exec["download_transparent"]
   }
 # configure transparent cursor
   exec {"make_transparent":
     command               => "/usr/bin/make install-data-local DESTDIR=/home/kiosk/.icons/default CURSOR_DIR=/cursors -k",
     cwd                   => "/tmp/xcursor-transparent-theme-0.1.1/cursors",
     unless                => "/usr/bin/test -f /home/kiosk/.icons/default/cursors/transp",
     require               => Exec["config_transparent"]
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
     comment               => "kiosk user",
     home                  => "/home/kiosk",
     ensure                => present,
     managehome            => true,
     password              => sha1('kiosk'),
   }
 # startx on login
   file { '/home/kiosk/.profile':
     ensure                => present,
     mode                  => '0644',
     content               => template("kiosk/.profile.erb"),
     require               => [User['kiosk']]
   }
 # autologin kiosk user
   file { '/etc/init/tty1.conf':
     ensure                => present,
     mode                  => '0644',
     content               => template("kiosk/tty1.conf.erb"),
     require               => [User['kiosk']]
   }
 # autostart openbox and disable screensaver/blanking
   file { '/home/kiosk/.xinitrc':
     ensure                => present,
     mode                  => '0644',
     owner                 => 'kiosk',
     content               => template("kiosk/.xinitrc.erb"),
     require               => [User['kiosk']]
   }
 # make userdirs
   file { $dirs:
     ensure                => 'directory',
     require               => User['kiosk'],
     owner                 => 'kiosk',
     group                 => 'kiosk',
     mode                  => '0644'
   }
 # ensure google-chrome config file
   file { '/home/kiosk/.config/google-chrome/Local State':
     ensure                => present,
     owner                 => 'kiosk',
     group                 => 'kiosk',
     mode                  => '0644',
     content               => template("kiosk/chrome-config.erb"),
     require               => [User['kiosk']]
   }
 # improve scrollbar
   file { '/home/kiosk/.config/google-chrome/Default/Extensions/manifest.json':
     ensure                => present,
     owner                 => 'kiosk',
     group                 => 'kiosk',
     mode                  => '0755',
     content               => template("kiosk/chrome-manifest.erb"),
     require               => [Package['google-chrome-stable'],File[$dirs]]
   }
   file { '/home/kiosk/.config/google-chrome/Default/Extensions/Custom.css':
     ensure                => present,
     owner                 => 'kiosk',
     group                 => 'kiosk',
     mode                  => '0755',
     content               => template("kiosk/chrome-css.erb"),
     require               => [Package['google-chrome-stable'],File[$dirs]]
   }
# autostart midori
    file { '/home/kiosk/.config/openbox/autostart.sh':
    ensure                => present,
    mode                  => '0644',
    content               => template("kiosk/openbox-autostart-java.sh.erb"),
    require               => [File['/home/kiosk/.config/openbox']]
    }
  common::directory_structure{ "/data/kiosk/${applet_name}":
    user                    => 'kiosk',
    mode                    => '0755'
  }
# download java applet
  file {"/data/kiosk/${applet_name}/${applet_name}.zip":
    source                => "puppet:///modules/kiosk/${applet_name}.zip",
    ensure                => "present",
    mode                  => "755",
    owner                 => "kiosk",
    group                 => "kiosk",
    require               => Common::Directory_structure["/data/kiosk/${applet_name}"]
  }
# unzip java applet
  exec {"unzip":
    command               => "/usr/bin/7z x -p${extractpassword} -aoa /data/kiosk/${applet_name}/${applet_name}.zip",
    cwd                   => "/data/kiosk/${applet_name}",
    unless                => "/usr/bin/test -f /data/kiosk/${applet_name}/data",
    require               => Common::Directory_structure["/data/kiosk/${applet_name}"]
  }
}
