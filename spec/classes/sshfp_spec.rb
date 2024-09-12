require 'spec_helper'

describe 'zonedit::sshfp' do
  let(:pre_condition) do
    <<~FUNCTION
      class { 'zonedit':
        git_pub_key => 'foo',
        git_priv_key => 'foo',
      }
      function zonedit::fetch_sshfp() {
        {
          'foo.example.org' => [
            'SSHFP 1 1 rsa_record',
            'SSHFP 1 2 rsa_record',
            'SSHFP 3 1 ecdsa-sha2-nistp256_record',
            'SSHFP 3 2 ecdsa-sha2-nistp256_record',
            'SSHFP 4 1 ed25519_record',
            'SSHFP 4 2 ed25519_record',
          ]
        }
      }
    FUNCTION
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with custom parameters' do
        let(:params) do
          {
            zone_file: '/var/zones/example.org.sshfp',
            parent_zone: 'example.org',
            use_puppetdb: true
          }
        end

        it { is_expected.to compile.with_all_deps }

        it 'contains sshfp resource with custom parameters' do
          is_expected.to contain_file('/var/zones/example.org.sshfp').with_content(
            <<~SSHFP,
              foo.example.org. 60 IN SSHFP 1 1 rsa_record
              foo.example.org. 60 IN SSHFP 1 2 rsa_record
              foo.example.org. 60 IN SSHFP 3 1 ecdsa-sha2-nistp256_record
              foo.example.org. 60 IN SSHFP 3 2 ecdsa-sha2-nistp256_record
              foo.example.org. 60 IN SSHFP 4 1 ed25519_record
              foo.example.org. 60 IN SSHFP 4 2 ed25519_record
            SSHFP
          )
        end
      end
    end
  end
end
