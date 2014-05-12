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
  $mode                                 = "undef",
  $packages                             = "undef",
  $midoridirs                           = "undef",
  $local_proxy                          = "undef",
  $http_port                            = "undef",
  $cache_mem                            = "undef",
  $cache_max_object_size                = "undef",
  $cache_maximum_object_size_in_memory  = "undef",
  $homepage                             = "undef",
  $acl_whitelist                        = "undef",
  $deny_info                            = "undef",
  $cache_peer                           = "undef",
  $extractpassword                      = "undef",
  $applet_name                          = "undef",
  $interactive_name                     = "undef"
)
{
  include kiosk::midori
# install packages
  package { $packages:
    ensure        => installed
  }
common::directory_structure{ "/data/kiosk/${applet_name}":
  user            => 'kiosk',
  mode            => '0755'
}
# download java applet
  file {"/data/kiosk/${applet_name}/${applet_name}.zip":
    source        => "puppet:///modules/kiosk/${applet_name}.zip",
    ensure        => "present",
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
# if local_proxy then install squid3
if $local_proxy   == 'true' {
# install squid
  package { 'squid3':
    ensure        => installed
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

# make whitelist usable with regex
  $acl_whitelist_real = join($acl_whitelist,'|')
# if cache_peer not set, use whitelist for caching
  if ($cache_peer) {
    $cache_peer_real = $cache_peer
  }
  else {
    $cache_peer_real = $acl_whitelist_real
  }
}
# if not local proxy:
  else  { notice("No local_proxy") }
