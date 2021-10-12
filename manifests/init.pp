# == Class: zonedit
#
class zonedit (
  String $git_pub_key,
  String $git_priv_key,
  String $git_user      = 'dns0ps',
  String $zones_repo    = 'git@git.dns.icann.org:zonedit/zones.git',
  String $zonedit_repo  = 'git@git.dns.icann.org:dns-eng/zonedit.git',
) {

  ensure_packages(['bind9utils', 'git'])
  python::pip {'GitPython':
    ensure       => '3.1.18',
    pip_provider => 'pip3',
  }
  ssh_authorized_key { 'git@zonedit.dns.icann.org':
    user => $git_user,
    type => 'ssh-rsa',
    key  => $git_pub_key,
  }
  file {'/var/git_repos':
    ensure => directory,
    owner  => $git_user,
  }
  file {'/etc/bash_completion.d/zonedit':
    ensure => present,
    source => 'puppet:///modules/zonedit/etc/bash_completion.d/zonedit',
  }
  file{"/home/${git_user}/.ssh/id_rsa":
    ensure  => file,
    owner   => $git_user,
    group   => $git_user,
    mode    => '0600',
    content => $git_priv_key,
  }
  vcsrepo {'/var/git_repos/zones':
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
    require  => File['/var/git_repos'],
  } -> file { '/usr/local/bin/zonedit':
    ensure => link,
    target => '/var/git_repos/zonedit/zonedit.py',
  }
}
