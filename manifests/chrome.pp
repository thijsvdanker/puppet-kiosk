# == Class: kiosk::chrome
#
# Puppet module to install chrome and local proxy
#
# === Authors
#
# foppe.pieters@naturalis.nl
#
# === Copyright
#
# Copyright 2014
#

class kiosk::chrome(
  $packages                             = ['xorg','openbox','build-essential','plymouth-theme-solar','ethtool'],
  $dirs                                 = ['/home/kiosk/','/home/kiosk/.config','/home/kiosk/.config/google-chrome','/home/kiosk/.config/google-chrome/Default','/home/kiosk/.config/google-chrome/Default/Extensions','/home/kiosk/.config/openbox','/home/kiosk/.icons/','/home/kiosk/.icons/default/','/home/kiosk/.icons/default/cursors'],
  $browser_path                         = "google-chrome --disable-translate --load-extension=/home/kiosk/.config/google-chrome/Default/Extensions/ --no-first-run --kiosk --allow-file-access-from-files https://localhost",
  $homepage                             = "https://localhost:808",
  $enable_apache                        = false,
  $webpackages                          = ['apache2','php5','libapache2-mod-php5','p7zip-full'],
  $extractpassword                      = undef,
  $applet_name                          = undef,
)
 { include stdlib
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
    mode                  => '0600',
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
# autostart chrome
  file { '/home/kiosk/.config/openbox/autostart.sh':
    ensure                => present,
    mode                  => '0644',
    content               => template("kiosk/openbox-autostart.sh.erb"),
    require               => [File['/home/kiosk/.config/openbox']]
    }

# if needed installs apache
  if ($enable_apache) {
  package { $webpackages:
    ensure                => present,
  }
  service { "apache2":
    ensure                => running,
    enable                => true,
    require               => Package['apache2'],
    subscribe             => [
                          File["/etc/apache2/mods-enabled/rewrite.load"],
                          File["/etc/apache2/sites-available/default"]
                          ],
    }
  file { "/etc/apache2/mods-enabled/rewrite.load":
    ensure                => link,
    target                => "/etc/apache2/mods-available/rewrite.load",
    require               => Package['apache2'],
  }

  file { "/etc/apache2/sites-available/default":
    ensure                => present,
    content               => template("kiosk/vhost.erb"),
    require               => Package['apache2'],
  }
# make www folder usable
  common::directory_structure{ "/var/www/html/":
    user                  => 'kiosk',
    mode                  => '0755',
    require               => Package['apache2']
  }
# download test template
  file {"/var/www/${applet_name}.zip":
    source                => "puppet:///modules/kiosk/${applet_name}.zip",
    ensure                => "present",
    mode                  => "755",
    owner                 => "kiosk",
    group                 => "kiosk",
    require               => Common::Directory_structure["/var/www/html/"],
    notify                => Exec['html5-unzip']
  }
# unzip template
  exec {"html5-unzip":
    command               => "/usr/bin/7z x -p${extractpassword} -aoa /var/www/${applet_name}.zip",
    cwd                   => "/var/www/html/",
    unless                => "/usr/bin/test -f /var/www/html/style.css",
    refreshonly           => true,
    require               => [ Common::Directory_structure["/var/www/html/"], File["/var/www/${applet_name}.zip"] ]
  }
  }
  else {
    notify{"Apache disabled": }
  }

}
