puppet-kiosk
===================
Puppet module to install a simple kiosk browser.It installs bare Xorg, Openbox window manager and:

* kiosk::midori =
Midori browser with mouse gestures and transparent mouse cursor, together with Squid3 local proxy.
* kiosk::java =
Midori browser with mouse gestures and transparent mouse cursor, together with java applet.
* kiosk::chromium =
Chromium browser gpu forced with mouse gestures and transparent mouse cursor, together with Squid3 local proxy. Made for html5.

Parameters
-------------
All parameters are read from defaults in init.pp and can be overwritten by hiera or The foreman.

```
kiosk::midori >
$packages                             = ['xorg','openbox','squid3'],
$dirs                                 = ['/home/kiosk/','/home/kiosk/.config','/home/kiosk/.config/midori','/home/kiosk/.config/midori/extensions','/home/kiosk/.config/midori/extensions/libmouse-gestures.so','/home/kiosk/.config/openbox','/home/kiosk/.local/','/home/kiosk/.local/share/','/home/kiosk/.local/share/midori','/home/kiosk/.local/share/midori/styles','/home/kiosk/.icons/','/home/kiosk/.icons/default/','/home/kiosk/.icons/default/cursors'],
$browser_path                         = "midori -i 300 -e Fullscreen -c /home/kiosk/.config/midori",
$homepage                             = "http://www.naturalis.nl/nl/het-museum/agenda/",
$acl_whitelist                        = [".naturalis.nl/nl/het-museum/agenda/",".naturalis.nl/media",".naturalis.nl/static/*"],
$deny_info                            = "http://www.naturalis.nl/nl/het-museum/agenda/",
$cache_peer                           = ".naturalis.nl/",
$http_port                            = "8080",
$cache_mem                            = "128 MB",
$cache_max_object_size                = "1024 MB",
$cache_maximum_object_size_in_memory  = "512 KB"

kiosk::java >
$packages                             = ['xorg','openbox','openjdk-7-jre','p7zip-full'],
$extractpassword                      = undef,
$applet_name                          = undef,
$interactive_name                     = undef,
$dirs                                 = ['/home/kiosk/','/home/kiosk/.config','/home/kiosk/.config/midori','/home/kiosk/.config/midori/extensions','/home/kiosk/.config/midori/extensions/libmouse-gestures.so','/home/kiosk/.config/openbox','/home/kiosk/.local/','/home/kiosk/.local/share/','/home/kiosk/.local/share/midori','/home/kiosk/.local/share/midori/styles','/home/kiosk/.icons/','/home/kiosk/.icons/default/','/home/kiosk/.icons/default/cursors']

kiosk::chromium >
$packages                             = ['xorg','openbox','squid3','build-essential'],
$dirs                                 = ['/home/kiosk/','/home/kiosk/.config','/home/kiosk/.config/chromium','/home/kiosk/.config/openbox','/home/kiosk/.icons/','/home/kiosk/.icons/default/','/home/kiosk/.icons/default/cursors'],
$browser_path                         = "chromium-browser --kiosk --incognito http://html5test.com",
$homepage                             = "http://www.naturalis.nl/nl/het-museum/agenda/",
$acl_whitelist                        = ['.naturalis.nl/nl/het-museum/agenda/|.naturalis.nl/media|.naturalis.nl/static/*'],
$deny_info                            = "http://www.naturalis.nl/nl/het-museum/agenda/",
$cache_peer                           = ['.naturalis.nl/nl/het-museum/agenda/'],
$http_port                            = "8080",
$cache_mem                            = "128 MB",
$cache_max_object_size                = "1024 MB",
$cache_maximum_object_size_in_memory  = "512 KB"
```
Limitations
-------------
This module has been built on and tested against Puppet 3.2.3 and higher.

The module has been tested on
- Ubuntu Server 12.04 LTS & 13.04

Dependencies
-------------
- stdlib

Authors
-------------
<foppe.pieters@naturalis.nl>
