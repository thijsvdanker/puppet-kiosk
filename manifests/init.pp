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
  $packages                             = ['xorg','openbox','squid3','unclutter'],
  $midoridirs                           = ['/home/kiosk/.config','/home/kiosk/.config/midori','/home/kiosk/.config/midori/extensions','/home/kiosk/.config/midori/extensions/libmouse-gestures.so','/home/kiosk/.config/openbox','/home/kiosk/.local/','/home/kiosk/.local/share/','/home/kiosk/.local/share/midori','/home/kiosk/.local/share/midori/styles'],
  $http_port                            = "8080",
  $cache_mem                            = "128 MB",
  $cache_max_object_size                = "1024 MB",
  $cache_maximum_object_size_in_memory  = "512 KB",
  $role                                 = "agenda",
  $homepage                             = undef,
  $acl_whitelist                        = undef,
  $deny_info                            = undef,
  $cache_peer                           = undef
)
{
  if $role == "agenda" {
    class {'kiosk::agenda':
    homepage           => $homepage,
    acl_whitelist      => $acl_whitelist,
    deny_info          => $deny_info,
    cache_peer         => $cache_peer
  }
}
  elsif $role == "earth" {
    class {'kiosk::earth':
    homepage           => $homepage,
    acl_whitelist      => $acl_whitelist,
    deny_info          => $deny_info,
    cache_peer         => $cache_peer
  }
}
  else {
        fail("unknown mode")
  }

  include stdlib

# make whitelist usable with regex
  $acl_whitelist_real = join($acl_whitelist,'|')
# if cache_peer not set, use whitelist for caching
  if ($cache_peer) {
    $cache_peer_real = $cache_peer
  }
  else {
    $cache_peer_real = $acl_whitelist_real
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
    mode          => '0444',
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

# autostart midori
  file { '/home/kiosk/.config/openbox/autostart.sh':
    ensure        => present,
    mode          => '0644',
    content       => template("kiosk/openbox-autostart.sh.erb"),
    require       => [Package['midori'],File[$midoridirs]]
  }
# improve scrollbar
  file { '/home/kiosk/.gtkrc-2.0':
    ensure        => present,
    mode          => '0644',
    content       => template("kiosk/.gtkrc-2.0.erb"),
    require       => [Package['midori'],File[$midoridirs]]
  }
}