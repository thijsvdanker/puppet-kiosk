# Class kiosk::agenda
#
#
class kiosk::agenda (
    $homepage                           = "http://www.naturalis.nl/nl/het-museum/agenda/",
    $acl_whitelist                      = ['.naturalis.nl/nl/het-museum/agenda/','.naturalis.nl/media','.naturalis.nl/static/*'],
    $deny_info                          = "http://www.naturalis.nl/nl/het-museum/agenda/",
    $cache_peer                         =  ".naturalis.nl/"
)
{
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