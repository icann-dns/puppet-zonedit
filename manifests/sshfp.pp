# @summary manage sshfp records in a zone file.  This class will create a zonefile snippet containing
#   the sshfp records a specific set of hosts.  The sshfp records can be fetched from puppetdb or provided
#   as a hash.  If fetched from puppetdb the sshfp records will be fetched from all hosts in puppetdb
# @param zone_file the zone file to manage
# @param parent_zone the parent zone of the zone file, will have a serial bump when zone_file changes
# @param use_puppetdb whether to use puppetdb to get the sshfp records
# @param perform_bump whether to perform a bump of the parent zone serial when the zone file changes
# @param ttl the ttl to use for the sshfp records
# @param sshfps a hash of sshfp records to manage.  theses records are also
#   included when use_puppetdb is vtrue
# @example
# class { 'zonedit::sshfp':
#  zone_file => '/var/named/db.example.com.sshfp',
#  parent_zone => 'example.com',
#  use_puppetdb => true,
# }
class zonedit::sshfp (
  Stdlib::Unixpath                     $zone_file,
  Stdlib::Fqdn                         $parent_zone,
  Boolean                              $use_puppetdb = false,
  Boolean                              $perform_bump = true,
  Integer[1]                           $ttl          = 60,
  Hash[Stdlib::Fqdn, Array[String[1]]] $sshfps       = {},
) {
  include zonedit

  $_sshfps = $use_puppetdb ? {
    true  => zonedit::fetch_sshfp() + $sshfps,
    false => $sshfps,
  }.filter |$fqdn, $records| {
    $records.size > 0
  }
  exec { "Bump ${parent_zone} serial":
    command     => "/usr/local/bin/zonedit --bump ${parent_zone}",
    user        => $zonedit::git_user,
    refreshonly => true,
  }
  file { $zone_file:
    ensure  => file,
    content => epp('zonedit/sshfp.epp', { 'sshfps' => $_sshfps , 'ttl' => $ttl }),
  }
  # This adds a notify to the file resource to bump the serial when the file changes
  if $perform_bump {
    File[$zone_file] ~> Exec["Bump ${parent_zone} serial"]
  }
}
