puppet-kiosk
===================
Puppet module to install a simple kiosk browser.
It only installs Xorg, Openbox window manager, Squid3 proxy, Midori browser with mouse gestures and Unclutter to hide the mouse cursor.

Parameters
-------------
All parameters are read from defaults in init.pp and can be overwritten by hiera or The foreman.

```
  $packages                             = ['xorg','openbox','squid3','unclutter'],
  $midoridirs                           = ['/home/kiosk/.config','/home/kiosk/.config/midori','/home/kiosk/.config/midori/extensions','/home/kiosk/.config/midori/extensions/libmouse-gestures.so','/home/kiosk/.config/openbox','/home/kiosk/.local/','/home/kiosk/.local/share/','/home/kiosk/.local/share/midori','/home/kiosk/.local/share/midori/styles'],
  $http_port                            = "8080",
  $cache_mem                            = "128 MB",
  $cache_max_object_size                = "1024 MB",
  $cache_maximum_object_size_in_memory  = "512 KB",
  $homepage                             = undef,
  $acl_whitelist                        = undef,
  $deny_info                            = undef,
  $cache_peer                           = undef
```
Limitations
-------------
This module has been built on and tested against Puppet 3.2.3 and higher.

The module has been tested on
- Ubuntu Server 12.04.4 LTS

Dependencies
-------------
- stdlib

Authors
-------------
<foppe.pieters@naturalis.nl>