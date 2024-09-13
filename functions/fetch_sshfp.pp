# @summnary this functions fetches the ssh fact from puppetdb and extracts the SSHFP records
# @return a hash of SSHFP records in the form of { 'fqdn' => [ 'record1', 'record2', ... ] }
# @example
# zonedit::fetch_sshfp() == { 'fqdn1' => [ 'record1', 'record2' ], 'fqdn2' => [ 'record1', 'record2' ] }
function zonedit::fetch_sshfp >> Hash[Stdlib::Fqdn, Array[String[1]]] {
  # The Puppet Query Language (PQL) query to fetch the ssh fact and certname
  $pql = 'inventory[certname,facts.ssh] { }'
  Hash(
    # puppetdb_query is a function from the puppetlabs/puppetdb module
    # Its used to fetch data about all nodes from puppet db.  in this case we are extracting the ssh fact
    # and the server certname (fqdn)
    puppetdb_query($pql).map |$data| {
      # We are only interested in the SSHFP records so we just extract the fingerprints from the ssh fact
      $records = $data['facts.ssh'].values.map |$record| { $record['fingerprints'].values }.flatten
      # We create a Key, Value pair of the certname and the SSHFP records this is later cast to a Hash
      [$data['certname'], $records]
    }.sort
  )
}
