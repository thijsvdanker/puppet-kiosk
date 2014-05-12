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
    $mode                                 = "agenda",
)
{
include stdlib

  if $mode == "agenda" {
    class {'kiosk::agenda':
      mode                                 => "agenda"
      packages                             => ['xorg','openbox','squid3','unclutter'],
      midoridirs                           => ['/home/kiosk/','/home/kiosk/.config','/home/kiosk/.config/midori','/home/kiosk/.config/midori/extensions','/home/kiosk/.config/midori/extensions/libmouse-gestures.so','/home/kiosk/.config/openbox','/home/kiosk/.local/','/home/kiosk/.local/share/','/home/kiosk/.local/share/midori','/home/kiosk/.local/share/midori/styles'],
      midori_path                          => "midori -i 300 -e Fullscreen -c /home/kiosk/.config/midori",
      local_proxy                          => "true",
      homepage                             => "http://www.naturalis.nl/nl/het-museum/agenda/",
      acl_whitelist                        => [".naturalis.nl/nl/het-museum/agenda/",".naturalis.nl/media",".naturalis.nl/static/*"],
      deny_info                            => "http://www.naturalis.nl/nl/het-museum/agenda/",
      cache_peer                           => ".naturalis.nl/",
      http_port                            => "8080",
      cache_mem                            => "128 MB",
      cache_max_object_size                => "1024 MB",
      cache_maximum_object_size_in_memory  => "512 KB",
    }

  } elsif $mode == "html5" {
      class {'kiosk::html5':
      mode                                 => "html5"
      packages                             => ['xorg','openbox','squid3','unclutter'],
      midoridirs                           => ['/home/kiosk/','/home/kiosk/.config','/home/kiosk/.config/midori','/home/kiosk/.config/midori/extensions','/home/kiosk/.config/midori/extensions/libmouse-gestures.so','/home/kiosk/.config/openbox','/home/kiosk/.local/','/home/kiosk/.local/share/','/home/kiosk/.local/share/midori','/home/kiosk/.local/share/midori/styles'],
      midori_path                          => "midori -i 300 -e Fullscreen -c /home/kiosk/.config/midori",
      local_proxy                          => "true",
      homepage                             => "http://www.naturalis.nl/nl/het-museum/agenda/",
      acl_whitelist                        => [".naturalis.nl/nl/het-museum/agenda/",".naturalis.nl/media",".naturalis.nl/static/*"],
      deny_info                            => "http://www.naturalis.nl/nl/het-museum/agenda/",
      cache_peer                           => ".naturalis.nl/",
      http_port                            => "8080",
      cache_mem                            => "128 MB",
      cache_max_object_size                => "1024 MB",
      cache_maximum_object_size_in_memory  => "512 KB",
    }

    } elsif $mode == "java" {
      class {'kiosk::java':
      mode                                 => "java"
      packages                             => ['xorg','openbox','openjdk-7-jre','unclutter','p7zip-full'],
      extractpassword                      => undef,
      applet_name                          => undef,
      interactive_name                     => undef,
      midoridirs                           => ['/home/kiosk/','/home/kiosk/.config','/home/kiosk/.config/midori','/home/kiosk/.config/midori/extensions','/home/kiosk/.config/midori/extensions/libmouse-gestures.so','/home/kiosk/.config/openbox','/home/kiosk/.local/','/home/kiosk/.local/share/','/home/kiosk/.local/share/midori','/home/kiosk/.local/share/midori/styles'],
      local_proxy                          => "true",
      homepage                             => "http://www.naturalis.nl/nl/het-museum/agenda/",
      acl_whitelist                        => [".naturalis.nl/nl/het-museum/agenda/",".naturalis.nl/media",".naturalis.nl/static/*"],
      deny_info                            => "http://www.naturalis.nl/nl/het-museum/agenda/",
      cache_peer                           => ".naturalis.nl/",
      http_port                            => "8080",
      cache_mem                            => "128 MB",
      cache_max_object_size                => "1024 MB",
      cache_maximum_object_size_in_memory  => "512 KB",
      }

    }else {
        fail("unknown mode")
  }
}
