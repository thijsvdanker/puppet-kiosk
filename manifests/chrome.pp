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
  $packages                             = ['xorg','openbox','squid3','build-essential'],
  $dirs                                 = ['/home/kiosk/','/home/kiosk/.config','/home/kiosk/.config/google-chrome','/home/kiosk/.config/google-chrome/Default','/home/kiosk/.config/google-chrome/Default/Extensions','/home/kiosk/.config/openbox','/home/kiosk/.icons/','/home/kiosk/.icons/default/','/home/kiosk/.icons/default/cursors'],
  $browser_path                         = "google-chrome --touch-events --touch-scrolling-mode --sync-touchmove --disable-translate --load-extension=/home/kiosk/.config/google-chrome/Default/Extensions --proxy-server=http://localhost:8080 --incognito --no-first-run --kiosk --homepage http://www.naturalis.nl/nl/het-museum/agenda/",
  $homepage                             = "http://www.naturalis.nl/nl/het-museum/agenda/",
  $acl_whitelist                        = ['.naturalis.nl/nl/het-museum/agenda/|.naturalis.nl/media|.naturalis.nl/static/*'],
  $deny_info                            = "http://www.naturalis.nl/nl/het-museum/agenda/",
  $cache_peer                           = ['.naturalis.nl/nl/het-museum/agenda/'],
  $http_port                            = "8080",
  $cache_mem                            = "128 MB",
  $cache_max_object_size                = "1024 MB",
  $cache_maximum_object_size_in_memory  = "512 KB",
  $enable_apache                        = "false"
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
#  apt::ppa { 'ppa:chromium-daily/stable':
#    require               => File['/etc/apt/sources.list.d']
#  }
# install latest chromium browser
#  package { 'chromium-browser':
#    ensure                => latest,
#    require               => Apt::Ppa['ppa:chromium-daily/stable']
#  }
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
  ## refresh:
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
    mode                  => '0644',
    content               => template("kiosk/chrome-config.erb"),
    require               => [User['kiosk']]
  }
# improve scrollbar
  file { '/home/kiosk/.config/google-chrome/Default/Extensions/manifest.json':
    ensure                => present,
    mode                  => '0644',
    content               => template("kiosk/chrome-manifest.erb"),
    require               => [Package['google-chrome-stable'],File[$dirs]]
  }
  file { '/home/kiosk/.config/google-chrome/Default/Extensions/Custom.css':
    ensure                => present,
    mode                  => '0644',
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
    //

  if $enable_apache == "true" {
    $installed            = present
    $enable               = true
    $ensure               = "running"
  } else {
    $installed            = absent
    $enable               = false
    $ensure               = "stopped"
  }
  package { 'apache2','php5','libapache2-mod-php5':
    ensure => $installed,
        }
  service { "apache2":
    ensure      => $ensure,
    enable      => $enable,
    require     => Package['apache2'],
    subscribe   => [
                File["/etc/apache2/mods-enabled/rewrite.load"],
                File["/etc/apache2/sites-available/default"],
                File["/etc/apache2/conf.d/phpmyadmin.conf"]
    ],
    }
  file { "/etc/apache2/mods-enabled/rewrite.load":
    ensure  => link,
    target  => "/etc/apache2/mods-available/rewrite.load",
    require => Package['apache2'],
    }

  file { "/etc/apache2/sites-available/default":
    ensure  => present,
    source  => "/vagrant/puppet/templates/vhost",
    require => Package['apache2'],
    }
  exec { 'echo "ServerName localhost" | sudo tee /etc/apache2/conf.d/fqdn':
    require => Package['apache2'],
    }
}
