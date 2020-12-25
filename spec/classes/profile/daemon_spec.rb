require 'spec_helper'

describe 'dockerinstall::profile::daemon' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      # this check is major for daemon profile
      it {
        is_expected.to contain_package('docker')
          .with_name('docker-ce')
          .that_notifies('Service[docker]')
      }

      it {
        is_expected.to contain_file('/etc/docker/daemon.json')
          .that_notifies('Service[docker]')
      }
    end
  end
end
