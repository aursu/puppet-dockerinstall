require 'spec_helper'

describe 'dockerinstall::swarm::node' do
  let(:title) { 'worker/sman1.domain.com' }
  let(:params) do
    {
      join_token: 'SWMTKN-1-2pt66je5c3fejw4adu8kcsoeid4rkk9fdy1s1bibm9plzuq8d0-ebcr22sn5z7cf9f76098v3gef',
      manager_node_ip: '10.100.16.60',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
