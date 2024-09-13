require 'spec_helper'

describe 'zonedit::fetch_sshfp' do
  describe 'one fact' do
    let(:pre_condition) do
      "function puppetdb_query($pql) {
        [
          {
            'certname' => 'foo.example.org',
            'facts.ssh' => {
              'rsa' => {
                'type' => 'ssh-rsa',
                'fingerprints' => {
                  'sha1' => 'SSHFP 1 1 rsa_record',
                  'sha256' => 'SSHFP 1 2 rsa_record'
                }
              },
              'ecdsa' => {
                'type' => 'ecdsa-sha2-nistp256',
                'fingerprints' => {
                  'sha1' => 'SSHFP 3 1 ecdsa-sha2-nistp256_record',
                  'sha256' => 'SSHFP 3 2 ecdsa-sha2-nistp256_record'
                }
              },
              'ed25519' => {
                'type' => 'ssh-ed25519',
                'fingerprints' => {
                  'sha1' => 'SSHFP 4 1 ed25519_record',
                  'sha256' => 'SSHFP 4 2 ed25519_record'
                }
              }
            }
          }
        ]
      }"
    end

    it do
      is_expected.to run.and_return({
                                      'foo.example.org' => [
                                        'SSHFP 1 1 rsa_record',
                                        'SSHFP 1 2 rsa_record',
                                        'SSHFP 3 1 ecdsa-sha2-nistp256_record',
                                        'SSHFP 3 2 ecdsa-sha2-nistp256_record',
                                        'SSHFP 4 1 ed25519_record',
                                        'SSHFP 4 2 ed25519_record',
                                      ]
                                    })
    end
  end
end
