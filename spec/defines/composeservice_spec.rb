require 'spec_helper'
require 'yaml'

describe 'dockerinstall::composeservice' do
  let(:configuration) { { 'services' => { 'centos7curlbuild' => {} } }.to_yaml }
  let(:rundir) { '/var/run/compose' }
  let(:libdir) { '/var/lib/compose' }
  let(:pre_condition) do
    <<-PRECOND
    class { 'dockerinstall': }
    class { 'dockerinstall::compose': }
    PRECOND
  end
  let(:title) { 'curl/centos7curlbuild' }
  let(:params) do
    {
      configuration: configuration,
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      # can not use File.stubs for directory? call
      # workaround is File[/var/run/compose] resource declaration
      if ['redhat-7-x86_64', 'centos-7-x86_64'].include?(os)
        let(:rundir) { '/run/compose' }
        let(:pre_condition) do
          <<-PRECOND
          class { 'dockerinstall': }
          class { 'dockerinstall::compose': }
          file { '/var/run/compose': ensure => directory, }
          PRECOND
        end
      end

      let(:params) do
        super().merge(
          'project_basedir' => rundir,
        )
      end
      let(:facts) { os_facts }

      it { is_expected.to compile }

      context 'when title has wrong format' do
        let(:title) { 'centos7curlbuild' }

        it {
          is_expected.to raise_error(Puppet::Error, %r{Composeservice title must be in format <project name>/<service name>})
        }
      end

      context 'when valid title (curl/centos7curlbuild) and configuration parameters' do
        let(:title) { 'rpmbuild-curl/centos7curlbuild' }

        it { is_expected.to contain_file(libdir + '/rpmbuild-curl') }
        it {
          is_expected.to contain_dockerservice('rpmbuild-curl/centos7curlbuild')
            .with(
              'ensure' => 'running',
              'configuration' => configuration,
              'project' => 'rpmbuild-curl',
              'build' => false,
            )
        }
      end

      context 'when build image requested' do
        let(:params) do
          super().merge(
            'build_image' => true,
          )
        end

        it {
          is_expected.to contain_dockerservice('curl/centos7curlbuild')
            .with(
              'ensure' => 'running',
              'configuration' => configuration,
              'project' => 'curl',
              'build' => true,
            )
        }
      end

      context 'when project_name specified (rpmbuild-curl-gitlab)' do
        let(:params) do
          super().merge(
            'project_name' => 'rpmbuild-curl-gitlab',
          )
        end

        it { is_expected.to contain_file(libdir + '/rpmbuild-curl-gitlab') }
        it {
          is_expected.to contain_dockerservice('curl/centos7curlbuild')
            .with(
              'project' => 'rpmbuild-curl-gitlab',
            )
        }
      end

      context 'when project_basedir specified (/var/lib/build)' do
        let(:params) do
          super().merge(
            'project_basedir' => '/var/lib/build',
          )
        end

        it { is_expected.to contain_file('/var/lib/build') }
        it { is_expected.to contain_file('/var/lib/build/curl') }
        it {
          is_expected.to contain_dockerservice('curl/centos7curlbuild')
            .with(
              'project' => 'curl',
              'basedir' => '/var/lib/build',
            )
        }
      end

      context 'when project_directory specified (/var/lib/build/rpmbuild-curl-gitlab)' do
        let(:params) do
          super().merge(
            'project_directory' => '/var/lib/build/rpmbuild-curl-gitlab',
          )
        end

        it { is_expected.to contain_file('/var/lib/build') }
        it { is_expected.to contain_file('/var/lib/build/rpmbuild-curl-gitlab') }
        it {
          is_expected.to contain_dockerservice('curl/centos7curlbuild')
            .with(
              'project' => '/var/lib/build/rpmbuild-curl-gitlab',
            )
        }
      end

      context 'when project_directory and project_basedir specified' do
        let(:params) do
          super().merge(
            'project_directory' => '/var/lib/build/rpmbuild-curl-gitlab',
            'project_basedir' => '/var/run/build',
          )
        end

        it { is_expected.to contain_file('/var/lib/build') }
        it { is_expected.to contain_file('/var/run/build') }
        it { is_expected.to contain_file('/var/lib/build/rpmbuild-curl-gitlab') }
        it {
          is_expected.to contain_dockerservice('curl/centos7curlbuild')
            .with(
              'project' => '/var/lib/build/rpmbuild-curl-gitlab',
              'basedir' => '/var/run/build',
            )
        }
      end

      context 'when configuration_path specified' do
        let(:params) do
          super().merge(
            'configuration_path' => '/var/lib/build/rpmbuild-curl-github/docker-compose.github.yaml',
          )
        end

        it { is_expected.to contain_file('/var/lib/build/rpmbuild-curl-github') }
        it {
          is_expected.to contain_dockerservice('curl/centos7curlbuild')
            .with(
              'path' => '/var/lib/build/rpmbuild-curl-github/docker-compose.github.yaml',
            )
        }
      end
    end
  end
end
