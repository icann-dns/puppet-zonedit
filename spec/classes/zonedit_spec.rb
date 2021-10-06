require 'spec_helper'

describe 'zonedit' do
  let(:node) { 'zonedit.example.com' }
  let(:params) do
    {
      git_pub_key: 'PUPLIC_KEY',
      git_priv_key: 'PRIVATE_KEY',
      git_user: "dns0ps",
      zones_repo: "git@git.dns.icann.org:zonedit/zones.git",
      zonedit_repo: "git@git.dns.icann.org:dns-eng/zonedit.git",
    }
  end

  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_python__pip('GitPython').with_ensure('3.1.18') }
        it do
          is_expected.to contain_ssh_authorized_key(
            'git@zonedit.dns.icann.org',
          ).with(
            user: 'dns0ps',
            type: 'ssh-rsa',
            key: 'PUPLIC_KEY',
          )
        end
        it do
          is_expected.to contain_file('/var/git_repos').with(
            ensure: 'directory',
            owner: 'dns0ps',
          )
        end
        it do
          is_expected.to contain_file('/etc/bash_completion.d/zonedit').with(
            ensure: 'present',
            source: 'puppet:///modules/zonedit/etc/bash_completion.d/zonedit',
          )
        end
        it do
          is_expected.to contain_file('/home/dns0ps/.ssh/id_rsa').with(
            ensure: 'file',
            owner: 'dns0ps',
            group: 'dns0ps',
            mode: '0600',
            content: 'PRIVATE_KEY',
          )
        end
        it do
          is_expected.to contain_vcsrepo('/var/git_repos/zones').with(
            ensure: 'latest',
            provider: 'git',
            revision: 'master',
            source: 'git@git.dns.icann.org:zonedit/zones.git',
            user: 'dns0ps',
            require: ['File[/var/git_repos]', 'File[/home/dns0ps/.ssh/id_rsa]'],
          )
        end
        it do
          is_expected.to contain_vcsrepo('/var/git_repos/zonedit').with(
            ensure: 'latest',
            provider: 'git',
            revision: 'master',
            user: 'dns0ps',
            source: 'git@git.dns.icann.org:dns-eng/zonedit.git',
            require: 'File[/var/git_repos]',
          )
        end
        it do
          is_expected.to contain_file('/usr/local/bin/zonedit').with(
            ensure: 'link',
            target: '/var/git_repos/zonedit/zonedit.py',
          )
        end
      end
      describe 'Change Defaults' do
        context 'git_pub_key' do
          before(:each) { params.merge!(git_pub_key: 'FOOBAR') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_ssh_authorized_key(
              'git@zonedit.dns.icann.org',
            ).with(
              user: 'dns0ps',
              type: 'ssh-rsa',
              key: 'FOOBAR',
            )
          end
        end
        context 'git_priv_key' do
          before(:each) { params.merge!(git_priv_key: 'FOOBAR') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/home/dns0ps/.ssh/id_rsa').with(
              ensure: 'file',
              owner: 'dns0ps',
              group: 'dns0ps',
              mode: '0600',
              content: 'FOOBAR',
            )
          end
        end
        context 'git_user' do
          before(:each) { params.merge!(git_user: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_ssh_authorized_key(
              'git@zonedit.dns.icann.org',
            ).with(
              user: 'foobar',
              type: 'ssh-rsa',
              key: 'PUPLIC_KEY',
            )
          end
          it do
            is_expected.to contain_file('/var/git_repos').with(
              ensure: 'directory',
              owner: 'foobar',
            )
          end
          it do
            is_expected.to contain_file('/home/foobar/.ssh/id_rsa').with(
              ensure: 'file',
              owner: 'foobar',
              group: 'foobar',
              mode: '0600',
              content: 'PRIVATE_KEY',
            )
          end
          it do
          is_expected.to contain_vcsrepo('/var/git_repos/zones').with(
            ensure: 'latest',
            provider: 'git',
            revision: 'master',
            source: 'git@git.dns.icann.org:zonedit/zones.git',
            user: 'foobar',
            require: ['File[/var/git_repos]', 'File[/home/foobar/.ssh/id_rsa]'],
          )
          end
          it do
            is_expected.to contain_vcsrepo('/var/git_repos/zonedit').with(
              ensure: 'latest',
              provider: 'git',
              revision: 'master',
              user: 'foobar',
              source: 'git@git.dns.icann.org:dns-eng/zonedit.git',
              require: 'File[/var/git_repos]',
            )
          end
        end
        context 'zones_repo' do
          before(:each) { params.merge!(zones_repo: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_vcsrepo('/var/git_repos/zones').with(
              ensure: 'latest',
              provider: 'git',
              revision: 'master',
              source: 'foobar',
              user: 'dns0ps',
              require: ['File[/var/git_repos]', 'File[/home/dns0ps/.ssh/id_rsa]'],
            )
          end
        end
        context 'zonedit_repo' do
          before(:each) { params.merge!(zonedit_repo: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_vcsrepo('/var/git_repos/zonedit').with(
              ensure: 'latest',
              provider: 'git',
              revision: 'master',
              user: 'dns0ps',
              source: 'foobar',
              require: 'File[/var/git_repos]',
            )
          end
        end
      end
      describe 'check bad type' do
        context 'git_pub_key' do
          before(:each) { params.merge!(git_pub_key: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'git_priv_key' do
          before(:each) { params.merge!(git_priv_key: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'git_user' do
          before(:each) { params.merge!(git_user: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'zones_repo' do
          before(:each) { params.merge!(zones_repo: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'zonedit_repo' do
          before(:each) { params.merge!(zonedit_repo: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
