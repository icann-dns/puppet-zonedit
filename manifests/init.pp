# @summary install and manage zonedit
# @param git_pub_key the ssh public key used to interact with git
# @param git_priv_key the ssh private key used to interact with git
# @param git_user the user used to interact with git
# @param zones_repo zones_repo the repository where zone files are stored
# @param zonedit_repo zonedit_repo the repository where zone files are stored
# @param zones_dir the directory where the zone files are stored
class zonedit (
  String $git_pub_key,
  String $git_priv_key,
  String $git_user            = 'dns0ps',
  String $zones_repo          = 'git@git.dns.icann.org:zonedit/zones.git',
  String $zonedit_repo        = 'git@git.dns.icann.org:dns-eng/zonedit.git',
  Stdlib::Unixpath $zones_dir = '/var/git_repos/zones',
) {
  ensure_packages(['bind9utils', 'git'])
  python::pip { 'GitPython':
    ensure       => 'present',
    pip_provider => 'pip3',
  }
  ssh_authorized_key { 'git@zonedit.dns.icann.org':
    user => $git_user,
    type => 'ssh-rsa',
    key  => $git_pub_key,
  }
  file { dirname($zones_dir):
    ensure => directory,
    owner  => $git_user,
  }
  file { '/etc/bash_completion.d/zonedit':
    ensure => file,
    source => 'puppet:///modules/zonedit/etc/bash_completion.d/zonedit',
  }
  file { "/home/${git_user}/.ssh/id_rsa":
    ensure  => file,
    owner   => $git_user,
    group   => $git_user,
    mode    => '0600',
    content => $git_priv_key,
  }
  vcsrepo { $zones_dir:
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => $zones_repo,
    user     => $git_user,
    require  => [
      File['/var/git_repos'],
      File["/home/${git_user}/.ssh/id_rsa"],
    ],
  }
  vcsrepo { '/var/git_repos/zonedit':
    ensure   => latest,
    provider => git,
    revision => 'master',
    user     => $git_user,
    source   => $zonedit_repo,
    require  => [
      File['/var/git_repos'],
      File["/home/${git_user}/.ssh/id_rsa"],
    ],
  }
  file { '/usr/local/bin/zonedit':
    ensure  => link,
    target  => '/var/git_repos/zonedit/zonedit.py',
    require => Vcsrepo['/var/git_repos/zonedit'],
  }
}
