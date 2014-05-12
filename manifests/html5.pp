# == Class: kiosk::html5
#
# Puppet module to install html5 modus
#
# === Authors
#
# foppe.pieters@naturalis.nl
#
# === Copyright
#
# Copyright 2014
#

class kiosk::html5(
  $packages                             = "undef",
  $midoridirs                           = "undef",
  $midori_path                          = "undef",
  $local_proxy                          = "undef",
  $http_port                            = "undef",
  $cache_mem                            = "undef",
  $cache_max_object_size                = "undef",
  $cache_maximum_object_size_in_memory  = "undef",
  $homepage                             = "undef",
  $acl_whitelist                        = "undef",
  $deny_info                            = "undef",
  $cache_peer                           = "undef"
)
{
  include kiosk::midori
# install packages
  package { $packages:
    ensure        => installed
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
  else { notice("No local_proxy") }
