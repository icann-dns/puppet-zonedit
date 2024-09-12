# @summary manage sshfp records in a zone file
# @param zone_file the zone file to manage§
# @param parent_zone the parent zone of the zone file, will have a serial bump when zone_file changes
# @param use_puppetdb whether to use puppetdb to get the sshfp records
# @param sshfps a hash of sshfp records to manage.  theses records are also
#   included when use_puppetdb is true
class zonedit::sshfp (
  Stdlib::Unixpath                     $zone_file,
  Stdlib::Fqdn                         $parent_zone,
  Boolean                              $use_puppetdb = false,
  Hash[Stdlib::Fqdn, Array[String[1]]] $sshfps       = {},
) {
  $_sshfps = $use_puppetdb ? {
    true  => zonedit::fetch_sshfp() + $sshfps,
    false => $sshfps,
  }
  file { $zone_file:
    ensure  => file,
    content => epp('zonedit/sshfp.epp', { 'sshfps' => $_sshfps }),
  }
  # TODO: bump the serial number
}
