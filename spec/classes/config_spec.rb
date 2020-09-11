require 'spec_helper'

describe 'dockerinstall::config' do
  let(:pre_condition) { 'include dockerinstall' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      context 'check bip option' do
        let(:params) do
          {
            bip: '192.168.0.1/24',
          }
        end

        it {
          is_expected.to contain_file('/etc/docker/daemon.json')
            .with_content(%r{\{"bip":"192\.168\.0\.1/24"\}})
        }
      end

      context 'check mtu option' do
        let(:params) do
          {
            mtu: 1460,
          }
        end

        it {
          is_expected.to contain_file('/etc/docker/daemon.json')
            .with_content(%r{\{"mtu":1460\}})
        }
      end

      context 'check devicemapper storage options' do
        let(:params) do
          {
            storage_opts: [
              'dm.fs=ext4',
            ],
          }
        end

        it {
          is_expected.to contain_file('/etc/docker/daemon.json')
            .with_content(%r{\{"storage-opts":\["dm.fs=ext4"\]\}})
        }
      end

      context 'check overlay2 storage options' do
        let(:params) do
          {
            storage_opts: [
              'overlay2.override_kernel_check=true',
            ],
          }
        end

        it {
          is_expected.to contain_file('/etc/docker/daemon.json')
            .with_content(%r{\{"storage-opts":\["overlay2.override_kernel_check=true"\]\}})
        }
      end

      context 'check overlay2 storage options' do
        let(:params) do
          {
            storage_opts: [
              'overlay2.blocksize=512K',
            ],
          }
        end

        it { is_expected.to compile.and_raise_error(%r{expects a match for Dockerinstall::StorageOptions}) }
      end
    end
  end
end
