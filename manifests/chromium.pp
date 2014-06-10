# == Class: kiosk::chromium
#
# Puppet module to install chromium and local proxy
#
# === Authors
#
# foppe.pieters@naturalis.nl
#
# === Copyright
#
# Copyright 2014
#

class kiosk::chromium(
  $packages                             = ['xorg','openbox','squid3','build-essential'],
  $dirs                                 = ['/home/kiosk/','/home/kiosk/.config','/home/kiosk/.config/chromium','/home/kiosk/.config/chromium/Default','/home/kiosk/.config/chromium/Default/Extensions','/home/kiosk/.config/openbox','/home/kiosk/.icons/','/home/kiosk/.icons/default/','/home/kiosk/.icons/default/cursors'],
  $browser_path                         = "chromium-browser --proxy-server=http://localhost:8080 --kiosk --incognito http://html5test.com",
  $homepage                             = "http://www.naturalis.nl/nl/het-museum/agenda/",
  $acl_whitelist                        = ['.naturalis.nl/nl/het-museum/agenda/|.naturalis.nl/media|.naturalis.nl/static/*'],
  $deny_info                            = "http://www.naturalis.nl/nl/het-museum/agenda/",
  $cache_peer                           = ['.naturalis.nl/nl/het-museum/agenda/'],
  $http_port                            = "8080",
  $cache_mem                            = "128 MB",
  $cache_max_object_size                = "1024 MB",
  $cache_maximum_object_size_in_memory  = "512 KB"
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
# add chromium key
  apt::ppa { 'ppa:chromium-daily/stable':
    require               => File['/etc/apt/sources.list.d']
  }
# install latest chromium browser
  package { 'chromium-browser':
    ensure                => latest,
    require               => Apt::Ppa['ppa:chromium-daily/stable']
  }
  # older is 'ppa:a-v-shkop/chromium'
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
# ensure chromium config file
  file { '/home/kiosk/.config/chromium/Local State':
    ensure                => present,
    mode                  => '0644',
    content               => template("kiosk/chromium-config.erb"),
    require               => [User['kiosk']]
  }
#  file { '/home/kiosk/.config/chromium/Default/Preferences':
#    ensure                => present,
#    mode                  => '0644',
#    content               => template("kiosk/chromium-config2.erb"),
#    require               => [User['kiosk']]
#  }
# improve scrollbar
  file { '/home/kiosk/.config/chromium/Default/Extensions/manifest.json':
    ensure                => present,
    mode                  => '0644',
    content               => template("kiosk/chromium-manifest.erb"),
    require               => [Package['chromium-browser'],File[$dirs]]
  }
  file { '/home/kiosk/.config/chromium/Default/Extensions/Custom.css':
    ensure                => present,
    mode                  => '0644',
    content               => template("kiosk/chromium-css.erb"),
    require               => [Package['chromium-browser'],File[$dirs]]
  }
# autostart chromium
  file { '/home/kiosk/.config/openbox/autostart.sh':
    ensure                => present,
    mode                  => '0644',
    content               => template("kiosk/openbox-autostart.sh.erb"),
    require               => [File['/home/kiosk/.config/openbox']]
    }
# make whitelist usable with regex
  $acl_whitelist_real = join($acl_whitelist,'|')
# if cache_peer not set, use whitelist for caching
  if ($cache_peer) {
    $cache_peer_real = $cache_peer
  }
  else {
    $cache_peer_real = $acl_whitelist_real
  }
# ensure squid is running
  service { 'squid3':
    enable                => true,
    ensure                => 'running',
    require               => File['/etc/squid3/squid.conf']
    }
# squid proxy config
  file { '/etc/squid3/squid.conf':
    ensure                => present,
    mode                  => '0644',
    content               => template("kiosk/squid.conf.erb"),
    require               => [Package[$packages]]
    }
}
