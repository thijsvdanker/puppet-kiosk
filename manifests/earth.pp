# Class kiosk::earth
#
#
class kiosk::earth (
    $homepage                             = "http://www.naturalis.nl/nl/het-museum/agenda/",
    $acl_whitelist                        = ['.naturalis.nl/nl/het-museum/agenda/','.naturalis.nl/media','.naturalis.nl/static/*'],
    $deny_info                            = "http://www.naturalis.nl/nl/het-museum/agenda/",
    $cache_peer                           =  ".naturalis.nl/"
)
{}