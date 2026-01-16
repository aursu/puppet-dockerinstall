require 'spec_helper'

describe 'dockerinstall::webservice' do
  let(:pre_condition) do
    <<-PRECOND
    include dockerinstall
    include dockerinstall::compose
    PRECOND
  end
  let(:title) { 'namevar' }
  let(:params) do
    {
      docker_image: 'jenkinsci/blueocean:1.19.0',
      manage_image: true,
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
          .without_configuration(%r{^version:})
      }

      it {
        is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
          .with_configuration(%r{^[ ]{2}namevar:$})
      }

      it {
        is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
          .with_configuration(%r{^[ ]{4}image: jenkinsci/blueocean:1\.19\.0$})
      }

      it {
        is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
          .with_configuration(%r{^[ ]{4}restart: always$})
      }

      context 'when docker ulimits specified' do
        let(:params) do
          super().merge(
            docker_ulimits: {
              memlock: [-1, -1],
              nofile: 65535,
            },
          )
        end

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{6}memlock:$})
            .with_configuration(%r{^[ ]{6}  soft: -1$})
            .with_configuration(%r{^[ ]{6}  hard: -1$})
        }

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{6}nofile: 65535$})
        }
      end

      context 'when docker build specified' do
        let(:params) do
          super().merge(
            docker_build: true,
          )
        end

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{4}build:$})
            .with_configuration(%r{^[ ]{4}  context: \.$})
            .with_configuration(%r{^[ ]{4}  dockerfile: Dockerfile$})
        }

        context 'when docker file and context specified' do
          let(:params) do
            super().merge(
              docker_context: '/var/run/compose/centos',
              docker_file: '6/curl/Dockerfile',
            )
          end

          it {
            is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
              .with_configuration(%r{^[ ]{4}build:$})
              .with_configuration(%r{^[ ]{4}  context: /var/run/compose/centos$})
              .with_configuration(%r{^[ ]{4}  dockerfile: 6/curl/Dockerfile$})
          }
        end

        context 'when docker build args specified' do
          let(:params) do
            super().merge(
              docker_build_args: { 'centos' => '7.8.2003' },
            )
          end

          it {
            is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
              .with_configuration(%r{^[ ]{4}build:$})
              .with_configuration(%r{^[ ]{4}  args:$})
              .with_configuration(%r{^[ ]{4}    centos: 7.8.2003$})
          }
        end
      end

      context 'when docker command specified' do
        let(:params) do
          super().merge(
            docker_command: 'bundle exec thin -p 3000',
          )
        end

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{4}command: bundle exec thin -p 3000$})
        }
      end

      context 'when docker command specified as array' do
        let(:params) do
          super().merge(
            docker_command: ['bundle', 'exec', 'thin', '-p', '3000'],
          )
        end

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{4}command: \["bundle", "exec", "thin", "-p", "3000"\]$})
        }
      end

      context 'when privileged flag is set' do
        let(:params) do
          super().merge(
            privileged: true,
          )
        end

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{4}privileged: true$})
        }
      end

      context 'when docker secrets specified' do
        let(:params) do
          super().merge(
            docker_secret: ['github_key', 'api_token'],
          )
        end

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{4}secrets:$})
            .with_configuration(%r{^[ ]{6}- github_key$})
            .with_configuration(%r{^[ ]{6}- api_token$})
        }
      end

      context 'when docker secret specified as string' do
        let(:params) do
          super().merge(
            docker_secret: ['db_password'],
          )
        end

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{4}secrets:$})
            .with_configuration(%r{^[ ]{6}- db_password$})
        }
      end

      context 'when project secrets specified' do
        let(:params) do
          super().merge(
            project_secrets: [
              {
                'name' => 'github_key',
                'type' => 'file',
                'value' => '/path/to/github.key',
              },
              {
                'name' => 'api_token',
                'type' => 'environment',
                'value' => 'API_TOKEN',
              },
            ],
          )
        end

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^secrets:$})
            .with_configuration(%r{^[ ]{2}github_key:$})
            .with_configuration(%r{^[ ]{4}file: /path/to/github\.key$})
        }

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{2}api_token:$})
            .with_configuration(%r{^[ ]{4}environment: API_TOKEN$})
        }
      end

      context 'when project secrets with setup flag specified' do
        let(:params) do
          super().merge(
            project_name: 'testapp',
            project_secrets: [
              {
                'name' => 'github_key',
                'type' => 'file',
                'value' => 'secret-key-content',
                'setup' => true,
                'filename' => 'github.pem',
              },
            ],
          )
        end

        it {
          is_expected.to contain_file('/var/lib/compose/testapp/secrets')
            .with_ensure('directory')
            .with_mode('0700')
        }

        it {
          is_expected.to contain_file('/var/lib/compose/testapp/secrets/github.pem')
            .with_ensure('file')
            .with_content('secret-key-content')
            .with_mode('0600')
        }

        it {
          is_expected.to contain_dockerinstall__composeservice('testapp/namevar')
            .with_configuration(%r{^secrets:$})
            .with_configuration(%r{^[ ]{2}github_key:$})
            .with_configuration(%r{^[ ]{4}file: secrets/github\.pem$})
        }
      end

      context 'when project secrets filename ends with .env' do
        let(:params) do
          super().merge(
            project_name: 'testapp',
            project_secrets: [
              {
                'name' => 'db_password',
                'type' => 'file',
                'value' => 'secret-db-password',
                'setup' => true,
                'filename' => 'database.env',
              },
            ],
          )
        end

        it {
          is_expected.to contain_file('/var/lib/compose/testapp/secrets/database.env.sec')
            .with_ensure('file')
            .with_content('secret-db-password')
            .with_mode('0600')
        }

        it {
          is_expected.to contain_dockerinstall__composeservice('testapp/namevar')
            .with_configuration(%r{^[ ]{4}file: secrets/database\.env\.sec$})
        }
      end

      context 'when both docker_secret and project_secrets specified' do
        let(:params) do
          super().merge(
            docker_secret: ['github_key'],
            project_secrets: [
              {
                'name' => 'github_key',
                'type' => 'file',
                'value' => '/run/secrets/github.pem',
              },
            ],
          )
        end

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{4}secrets:$})
            .with_configuration(%r{^[ ]{6}- github_key$})
        }

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^secrets:$})
            .with_configuration(%r{^[ ]{2}github_key:$})
            .with_configuration(%r{^[ ]{4}file: /run/secrets/github\.pem$})
        }
      end
    end
  end
end
