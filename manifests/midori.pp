# == Class: kiosk::midori
#
# Puppet module to install midori and local proxy
#
# === Authors
#
# foppe.pieters@naturalis.nl
#
# === Copyright
#
# Copyright 2014
#

class kiosk::midori(
  $packages                             = ['xorg','openbox','squid3','build-essential', 'nspluginwrapper','ia32-libs'],
  $midoridirs                           = ['/home/kiosk/','/home/kiosk/.config','/home/kiosk/.config/midori','/home/kiosk/.config/midori/extensions','/home/kiosk/.config/midori/extensions/libmouse-gestures.so','/home/kiosk/.config/openbox','/home/kiosk/.local/','/home/kiosk/.local/share/','/home/kiosk/.local/share/midori','/home/kiosk/.local/share/midori/styles','/home/kiosk/.icons/','/home/kiosk/.icons/default/','/home/kiosk/.icons/default/cursors','/home/kiosk/.mozilla/','/home/kiosk/.mozilla/plugins/'],
  $midori_path                          = "midori -i 300 -e Fullscreen -c /home/kiosk/.config/midori",
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
    command               => "/bin/sh -c ./configure && cd cursors && make install-data-local DESTDIR=/home/kiosk/.icons/default CURSOR_DIR=/cursors",
    cwd                   => "/tmp/xcursor-transparent-theme-0.1.1",
    path                  => "/usr/bin/",
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
    content       => template("kiosk/openbox-autostart.sh.erb"),
    require       => [File['/home/kiosk/.config/openbox']]
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
      enable        => true,
      ensure        => 'running',
      require       => File['/etc/squid3/squid.conf']
    }
# squid proxy config
    file { '/etc/squid3/squid.conf':
      ensure        => present,
      mode          => '0644',
      content       => template("kiosk/squid.conf.erb"),
      require       => [Package[$packages]]
    }
# download and untar html5 fix
#      exec { 'download_fix':
#          command        => "/usr/bin/curl http://fpdownload.macromedia.com/get/flashplayer/pdc/11.2.202.310/install_flash_player_11_linux.i386.tar.gz -o /tmp/install_flash_player_11_linux.i386.tar.gz && /bin/tar -xf /tmp/install_flash_player_11_linux.i386.tar.gz -C /home/kiosk/.mozilla/plugins/",
#          unless         => "/usr/bin/test -f /home/kiosk/.mozilla/plugins/libflashplayer.so",
#          require        => [Package[$packages]]
#      }
}
