require 'spec_helper'

describe 'dockerinstall::service' do
  let(:pre_condition) { 'include dockerinstall' }

  on_supported_os.each do |os, os_facts|
    os_facts[:systemd] = true

    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_service('docker')
          .that_subscribes_to('File[/etc/docker/daemon.json]')
      }

      it {
        is_expected.to contain_service('docker')
          .that_requires('User[docker]')
      }

      it {
        is_expected.to contain_service('docker')
          .that_requires('Package[docker]')
      }

      it {
        is_expected.to contain_file('/etc/systemd/system/docker.service.d')
      }

      it {
        is_expected.to contain_file('/etc/systemd/system/docker.service.d/service-overrides.conf')
          .that_requires('User[docker]')
      }

      case os
      when %r{ubuntu}
        it {
          is_expected.to contain_file('/etc/default/docker-storage')
            .that_notifies('Service[docker]')
        }
        it {
          is_expected.to contain_file('/etc/default/docker')
            .that_notifies('Service[docker]')
        }
      when %r{centos}
        it {
          is_expected.to contain_file('/etc/sysconfig/docker-storage')
            .that_notifies('Service[docker]')
        }
        it {
          is_expected.to contain_file('/etc/sysconfig/docker')
            .that_notifies('Service[docker]')
        }
      end
    end
  end
end
