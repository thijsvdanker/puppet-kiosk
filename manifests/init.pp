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
    $extractpassword                       = undef,
    $applet_name                           = undef,
    $interactive_name                      = undef
)
{
include stdlib

  if $mode == "agenda" {
    class {'kiosk::agenda':
    }

  } elsif $mode == "html5" {
      class {'kiosk::html5':
    }

    } elsif $mode == "java" {
      class {'kiosk::java':
      }

    }else {
        fail("unknown mode")
  }
}
