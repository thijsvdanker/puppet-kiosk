puppet-kiosk
===================
Puppet module to install a simple kiosk browser.
It only installs Xorg, Openbox window manager, Squid3 proxy, Midori browser with mouse gestures and Unclutter to hide the mouse cursor.

Errors
-------------
Mouse gestures dont work yet!

Parameters
-------------
All parameters are read from defaults in init.pp and can be overwritten by hiera or The foreman.

```
  $packages                             = ['xorg','openbox','squid3','unclutter'],

  # squid3 config:
  $http_port                            = "8080",
  $acl_whitelist                        = ['.naturalis.nl/nl/het-museum/agenda/','.naturalis.nl/media','.naturalis.nl/static/*'],
  $deny_info                            = "http://www.naturalis.nl/nl/het-museum/agenda/",
  $cache_peer                           =  ".naturalis.nl/",
  $cache_mem                            = "128 MB",
  $cache_max_object_size                = "1024 MB"
  $cache_maximum_object_size_in_memory  = "512 KB"
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