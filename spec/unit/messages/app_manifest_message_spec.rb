require 'spec_helper'
require 'messages/app_manifest_message'

module VCAP::CloudController
  RSpec.describe AppManifestMessage do
    describe 'validations' do
      context 'when unexpected keys are requested' do
        let(:params) { { instances: 3, memory: '2G', name: 'foo' } }

        it 'is valid' do
          message = AppManifestMessage.new(params)

          expect(message).to be_valid
        end
      end

      describe 'memory' do
        context 'when memory unit is not part of expected set of values' do
          let(:params) { { memory: '200INVALID' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Memory must use a supported unit: B, K, KB, M, MB, G, GB, T, or TB')
          end
        end

        context 'when memory is not a positive amount' do
          let(:params) { { memory: '-1MB' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Memory must be greater than 0MB')
          end
        end

        context 'when memory is in bytes' do
          let(:params) { { memory: '-35B' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Memory must be greater than 0MB')
          end
        end
      end

      describe 'disk_quota' do
        context 'when disk_quota unit is not part of expected set of values' do
          let(:params) { { disk_quota: '200INVALID' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Disk quota must use a supported unit: B, K, KB, M, MB, G, GB, T, or TB')
          end
        end

        context 'when disk_quota is not a positive amount' do
          let(:params) { { disk_quota: '-1MB' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Disk quota must be greater than 0MB')
          end
        end

        context 'when disk_quota is not numeric' do
          let(:params) { { disk_quota: 'gerg herscheiser' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Disk quota is not a number')
          end
        end
      end

      describe 'buildpack' do
        context 'when providing a valid buildpack name' do
          let(:buildpack) { Buildpack.make }
          let(:params) { { buildpack: buildpack.name } }

          it 'is valid' do
            message = AppManifestMessage.new(params)

            expect(message).to be_valid
          end
        end

        context 'when the buildpack is not a string' do
          let(:params) { { buildpack: 99 } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Buildpacks can only contain strings')
          end
        end
      end

      describe 'stack' do
        context 'when providing a valid stack name' do
          let(:params) { { stack: 'cflinuxfs2' } }

          it 'is valid' do
            message = AppManifestMessage.new(params)

            expect(message).to be_valid
            expect(message.stack).to eq('cflinuxfs2')
          end
        end

        context 'when the stack is not a string' do
          let(:params) { { stack: 99 } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Stack must be a string')
          end
        end
      end

      describe 'instances' do
        context 'when instances is not an number' do
          let(:params) { { instances: 'silly string thing' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Instances is not a number')
          end
        end

        context 'when instances is not an integer' do
          let(:params) { { instances: 3.5 } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Instances must be an integer')
          end
        end

        context 'when instances is not a positive integer' do
          let(:params) { { instances: -1 } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Instances must be greater than or equal to 0')
          end
        end
      end

      describe 'env' do
        context 'when env is not a hash' do
          let(:params) do
            {
              env: 'im a non-hash'
            }
          end
          it 'is not valid' do
            message = AppManifestMessage.new(params)
            expect(message).to_not be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('env must be a hash of keys and values')
          end
        end

        context 'when env has bad keys' do
          let(:params) do
            {
              env: {
                "": 'null-key',
                VCAP_BAD_KEY: 1,
                VMC_BAD_KEY: %w/hey it's an array/,
                PORT: 5,
              }
            }
          end
          it 'is not valid' do
            message = AppManifestMessage.new(params)
            expect(message).to_not be_valid
            expect(message.errors.count).to eq(4)
            expect(message.errors.full_messages).to match_array([
              'Env cannot set PORT',
              'Env cannot start with VCAP_',
              'Env cannot start with VMC_',
              'Env key must be a minimum length of 1'])
          end
        end
      end

      describe 'routes' do
        context 'when all routes are valid' do
          let(:params) do
            { routes:
              [
                { route: 'existing.example.com' },
                { route: 'new.example.com' },
              ]
            }
          end

          it 'returns true' do
            message = AppManifestMessage.new(params)

            expect(message).to be_valid
          end
        end

        context 'when a route uri is invalid' do
          let(:params) do
            { routes:
              [
                { route: 'blah' },
                { route: 'anotherblah' },
                { route: 'http://example.com' },
              ]
            }
          end

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.full_messages).to match_array(["The route 'anotherblah' is not a properly formed URL", "The route 'blah' is not a properly formed URL"])
          end
        end

        context 'when routes are malformed' do
          let(:params) { { routes: ['blah'] } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)

            expect(message).not_to be_valid
            expect(message.errors.full_messages).to match_array(['Routes must be a list of route hashes'])
          end
        end

        context 'when no-route is specified' do
          let(:params) { { 'no-route' => no_route_val } }

          context 'when no-route is true' do
            let(:no_route_val) { true }

            it 'is valid' do
              message = AppManifestMessage.create_from_yml(params)
              expect(message).to be_valid
            end
          end

          context 'when no-route is not a boolean' do
            let(:no_route_val) { 'I am a free s0mjgnbha' }

            it 'is not valid' do
              message = AppManifestMessage.create_from_yml(params)
              expect(message).not_to be_valid
              expect(message.errors.full_messages).to match_array(['No-route must be a boolean'])
            end
          end

          context 'when no-route is true and routes are specified' do
            let(:params) do
              {
                no_route: true,
                routes:
                [
                  { route: 'http://example.com' }
                ]
              }
            end

            it 'is not valid' do
              message = AppManifestMessage.create_from_yml(params)
              expect(message).not_to be_valid
              expect(message.errors.full_messages).to match_array(['Cannot use the combination of properties: no-route, routes'])
            end
          end
        end

        context 'when random_route is specified' do
          let(:params) { { 'random_route' => random_route_val } }

          context 'when random_route is true' do
            let(:random_route_val) { true }

            it 'is valid' do
              message = AppManifestMessage.create_from_yml(params)
              expect(message).to be_valid
            end
          end

          context 'when random_route is not a boolean' do
            let(:random_route_val) { 'I am a free s0mjgnbha' }

            it 'is not valid' do
              message = AppManifestMessage.create_from_yml(params)
              expect(message).not_to be_valid
              expect(message.errors.full_messages).to match_array(['Random-route must be a boolean'])
            end
          end

          context 'when random_route is true and routes are specified' do
            let(:params) do
              {
                random_route: true,
                routes:
                  [
                    { route: 'http://example.com' }
                  ]
              }
            end

            it 'is valid' do
              message = AppManifestMessage.create_from_yml(params)
              expect(message).to be_valid
            end
          end
        end
      end

      describe 'services bindings' do
        context 'when services is not an array' do
          let(:params) do
            {
              services: 'string'
            }
          end

          it 'is not valid' do
            message = AppManifestMessage.new(params)
            expect(message).to_not be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Services must be a list of service instance names')
          end
        end
      end

      describe 'processes' do
        context 'when processes is not an array' do
          let(:params) { { processes: 'string' } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)
            expect(message).to_not be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('Processes must be an array of process configurations')
          end
        end

        context 'when any process does not have a type' do
          let(:params) { { processes: [{ 'instances' => 3 }] } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)
            expect(message).to_not be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('All Processes must specify a type')
          end
        end

        context 'when any process has a blank type' do
          let(:params) { { processes: [{ 'type' => '', 'instances' => 3 }] } }

          it 'is not valid' do
            message = AppManifestMessage.new(params)
            expect(message).to_not be_valid
            expect(message.errors.count).to eq(1)
            expect(message.errors.full_messages).to include('All Processes must specify a type')
          end
        end

        context 'when there is more than one process with the same type' do
          let(:params) { { processes: [{ 'type' => 'foo', 'instances' => 3 }, { 'type' => 'foo', 'instances' => 1 },
                                       { 'type' => 'bob', 'instances' => 5 }, { 'type' => 'bob', 'instances' => 1 }
          ] }
          }

          it 'is not valid' do
            message = AppManifestMessage.new(params)
            expect(message).to_not be_valid
            expect(message.errors.count).to eq(2)
            expect(message.errors.full_messages).to include('foo Process may only be present once')
            expect(message.errors.full_messages).to include('bob Process may only be present once')
          end
        end
      end

      context 'when there are multiple errors' do
        let(:params) do
          {
            instances: -1,
            memory: 120,
            disk_quota: '-120KB',
            buildpack: 99,
            stack: 42,
            env: %w/not a hash/
          }
        end

        it 'is not valid' do
          message = AppManifestMessage.new(params)

          expect(message).not_to be_valid
          expect(message.errors.count).to eq(6)
          expect(message.errors.full_messages).to match_array([
            'Instances must be greater than or equal to 0',
            'Memory must use a supported unit: B, K, KB, M, MB, G, GB, T, or TB',
            'Disk quota must be greater than 0MB',
            'Buildpacks can only contain strings',
            'Stack must be a string',
            'env must be a hash of keys and values',
          ])
        end
      end
    end

    describe '.create_from_yml' do
      let(:parsed_yaml) { { 'name' => 'blah', 'instances' => 4, 'memory' => '200GB' } }

      it 'returns the correct AppManifestMessage' do
        message = AppManifestMessage.create_from_yml(parsed_yaml)

        expect(message).to be_valid
        expect(message).to be_a(AppManifestMessage)
        expect(message.instances).to eq(4)
        expect(message.memory).to eq('200GB')
      end

      it 'converts requested keys to symbols' do
        message = AppManifestMessage.create_from_yml(parsed_yaml)

        expect(message.requested?(:instances)).to be_truthy
        expect(message.requested?(:memory)).to be_truthy
      end
    end

    describe '#process_scale_message' do
      context 'from app-level attributes' do
        let(:parsed_yaml) { { 'disk_quota' => '1000GB', 'memory' => '200GB', instances: 5 } }

        it 'returns a ManifestProcessScaleMessage containing mapped attributes' do
          message = AppManifestMessage.create_from_yml(parsed_yaml)

          expect(message).to be_valid
          expect(message.manifest_process_scale_messages.length).to eq(1)
          expect(message.manifest_process_scale_messages.first.instances).to eq(5)
          expect(message.manifest_process_scale_messages.first.memory).to eq(204800)
          expect(message.manifest_process_scale_messages.first.disk_quota).to eq(1024000)
          expect(message.manifest_process_scale_messages.first.type).to eq('web')
        end

        context 'it handles bytes' do
          let(:parsed_yaml) { { 'disk_quota' => '7340032B', 'memory' => '3145728B', instances: 8 } }

          it 'returns a ManifestProcessScaleMessage containing mapped attributes' do
            message = AppManifestMessage.create_from_yml(parsed_yaml)

            expect(message).to be_valid
            expect(message.manifest_process_scale_messages.length).to eq(1)
            expect(message.manifest_process_scale_messages.first.instances).to eq(8)
            expect(message.manifest_process_scale_messages.first.memory).to eq(3)
            expect(message.manifest_process_scale_messages.first.disk_quota).to eq(7)
          end
        end

        context 'it handles exactly 1MB' do
          let(:parsed_yaml) { { 'disk_quota' => '1048576B', 'memory' => '1048576B', instances: 8 } }

          it 'returns a ManifestProcessScaleMessage containing mapped attributes' do
            message = AppManifestMessage.create_from_yml(parsed_yaml)

            expect(message).to be_valid
            expect(message.manifest_process_scale_messages.length).to eq(1)
            expect(message.manifest_process_scale_messages.first.instances).to eq(8)
            expect(message.manifest_process_scale_messages.first.memory).to eq(1)
            expect(message.manifest_process_scale_messages.first.disk_quota).to eq(1)
          end
        end

        context 'it complains about 1MB - 1' do
          let(:parsed_yaml) { { 'disk_quota' => '1048575B', 'memory' => '1048575B', instances: 8 } }

          it 'returns a ManifestProcessScaleMessage containing mapped attributes' do
            message = AppManifestMessage.create_from_yml(parsed_yaml)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(2)
            expect(message.errors.full_messages).to match_array(['Memory must be greater than 0MB', 'Disk quota must be greater than 0MB'])
          end
        end

        context 'when attributes are not requested in the manifest' do
          let(:parsed_yaml) { {} }

          it 'does not create any ManifestProcessScaleMessages' do
            message = AppManifestMessage.create_from_yml(parsed_yaml)

            expect(message.manifest_process_scale_messages.length).to eq(0)
          end
        end
      end

      context 'from nested process attributes' do
        let(:parsed_yaml) { { 'processes' => [{ 'type' => 'web', 'disk_quota' => '1000GB', 'memory' => '200GB', instances: 5 }] } }

        it 'returns a ManifestProcessScaleMessage containing mapped attributes' do
          message = AppManifestMessage.create_from_yml(parsed_yaml)

          expect(message).to be_valid
          expect(message.manifest_process_scale_messages.length).to eq(1)
          expect(message.manifest_process_scale_messages.first.instances).to eq(5)
          expect(message.manifest_process_scale_messages.first.memory).to eq(204800)
          expect(message.manifest_process_scale_messages.first.disk_quota).to eq(1024000)
          expect(message.manifest_process_scale_messages.first.type).to eq('web')
        end

        context 'it handles bytes' do
          let(:parsed_yaml) { { 'processes' => [{ 'type' => 'web', 'disk_quota' => '7340032B', 'memory' => '3145728B', instances: 8 }] } }

          it 'returns a ManifestProcessScaleMessage containing mapped attributes' do
            message = AppManifestMessage.create_from_yml(parsed_yaml)

            expect(message).to be_valid
            expect(message.manifest_process_scale_messages.length).to eq(1)
            expect(message.manifest_process_scale_messages.first.instances).to eq(8)
            expect(message.manifest_process_scale_messages.first.memory).to eq(3)
            expect(message.manifest_process_scale_messages.first.disk_quota).to eq(7)
          end
        end

        context 'it handles exactly 1MB' do
          let(:parsed_yaml) { { 'processes' => [{ 'type' => 'web', 'disk_quota' => '1048576B', 'memory' => '1048576B', instances: 8 }] } }

          it 'returns a ManifestProcessScaleMessage containing mapped attributes' do
            message = AppManifestMessage.create_from_yml(parsed_yaml)

            expect(message).to be_valid
            expect(message.manifest_process_scale_messages.length).to eq(1)
            expect(message.manifest_process_scale_messages.first.instances).to eq(8)
            expect(message.manifest_process_scale_messages.first.memory).to eq(1)
            expect(message.manifest_process_scale_messages.first.disk_quota).to eq(1)
          end
        end

        context 'it complains about 1MB - 1' do
          let(:parsed_yaml) { { 'processes' => [{ 'type' => 'web', 'disk_quota' => '1048575B', 'memory' => '1048575B', instances: 8 }] } }

          it 'returns a ManifestProcessScaleMessage containing mapped attributes' do
            message = AppManifestMessage.create_from_yml(parsed_yaml)

            expect(message).not_to be_valid
            expect(message.errors.count).to eq(2)
            expect(message.errors.full_messages).to match_array(['Memory must be greater than 0MB', 'Disk quota must be greater than 0MB'])
          end
        end

        context 'when processes and app-level process properties are specified' do
          context 'there is a web process type on the process level' do
            let(:parsed_yaml) { { 'memory' => '5GB',
                                  instances: 1,
                                  'disk_quota' => '30GB',
                                  'processes' => [{ 'type' => 'web', 'disk_quota' => '1000GB', 'memory' => '200GB', instances: 5 }] }
            }

            it 'uses the values from the web process and ignores the app-level process properties' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)

              expect(message).to be_valid
              expect(message.manifest_process_scale_messages.length).to eq(1)
              expect(message.manifest_process_scale_messages.first.instances).to eq(5)
              expect(message.manifest_process_scale_messages.first.memory).to eq(204800)
              expect(message.manifest_process_scale_messages.first.disk_quota).to eq(1024000)
              expect(message.manifest_process_scale_messages.first.type).to eq('web')
            end
          end

          context 'there is not a web process type on the process level' do
            let(:parsed_yaml) { { 'memory' => '5GB',
                                  instances: 1,
                                  'disk_quota' => '30GB',
                                  'processes' => [{ 'type' => 'worker', 'disk_quota' => '1000GB', 'memory' => '200GB', instances: 5 }] }
            }

            it 'uses the values from the app-level process for the web process' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)

              expect(message).to be_valid
              expect(message.manifest_process_scale_messages.length).to eq(2)

              expect(message.manifest_process_scale_messages.first.instances).to eq(1)
              expect(message.manifest_process_scale_messages.first.memory).to eq(5120)
              expect(message.manifest_process_scale_messages.first.disk_quota).to eq(30720)
              expect(message.manifest_process_scale_messages.first.type).to eq('web')

              expect(message.manifest_process_scale_messages.last.type).to eq('worker')
              expect(message.manifest_process_scale_messages.last.instances).to eq(5)
              expect(message.manifest_process_scale_messages.last.memory).to eq(204800)
              expect(message.manifest_process_scale_messages.last.disk_quota).to eq(1024000)
            end
          end
        end
      end
    end

    describe '#process_update_message' do
      context 'from app-level attributes' do
        let(:parsed_yaml) do
          {
            'command' => command,
            'health-check-type' => health_check_type,
            'health-check-http-endpoint' => health_check_http_endpoint,
            'timeout' => health_check_timeout
          }
        end

        let(:command) { 'new-command' }
        let(:health_check_type) { 'http' }
        let(:health_check_http_endpoint) { '/endpoint' }
        let(:health_check_timeout) { 10 }

        context 'when new properties are specified' do
          it 'sets the command and health check type fields in the message' do
            message = AppManifestMessage.create_from_yml(parsed_yaml)
            expect(message).to be_valid
            expect(message.manifest_process_update_messages.length).to eq(1)
            expect(message.manifest_process_update_messages.first.command).to eq('new-command')
            expect(message.manifest_process_update_messages.first.health_check_type).to eq('http')
            expect(message.manifest_process_update_messages.first.health_check_endpoint).to eq('/endpoint')
            expect(message.manifest_process_update_messages.first.health_check_timeout).to eq(10)
          end
        end

        context 'health checks' do
          context 'deprecated health check type none' do
            let(:parsed_yaml) { { "health-check-type": 'none' } }

            it 'is converted to process' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.health_check_type).to eq('process')
            end
          end

          context 'health check timeout without other health check parameters' do
            let(:health_check_timeout) { 10 }
            let(:parsed_yaml) { { "timeout": health_check_timeout } }

            it 'sets the health check timeout in the message' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.health_check_timeout).to eq(10)
            end
          end

          context 'when health check type is http and endpoint is not specified' do
            let(:parsed_yaml) { { 'health-check-type' => 'http' } }

            it 'defaults endpoint to "/"' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.health_check_type).to eq('http')
              expect(message.manifest_process_update_messages.first.health_check_endpoint).to eq('/')
            end
          end

          context 'when health check type is not http and endpoint is not specified' do
            let(:parsed_yaml) { { 'health-check-type' => 'port' } }

            it 'does not default endpoint to "/"' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.health_check_type).to eq('port')
              expect(message.manifest_process_update_messages.first.health_check_endpoint).to be_nil
            end
          end
        end

        context 'command' do
          context 'when a string command of value "null" is specified' do
            let(:command) { 'null' }

            it 'does not set the command field in the process update message' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.command).to eq('null')
            end
          end

          # This happens when users specify `command: ` with no value in the manifest.
          context 'when a nil command (value nil) is specified' do
            let(:command) { nil }

            it 'sets the field as null in the process update message' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.command).to eq('null')
            end
          end

          context 'when a default command is specified' do
            let(:command) { 'default' }

            it 'does not set the command field in the process update message' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.command).to eq('default')
            end
          end
        end

        context 'when no parameters is specified' do
          let(:parsed_yaml) do
            {}
          end

          it 'does not set a command or health_check_type field' do
            message = AppManifestMessage.create_from_yml(parsed_yaml)
            expect(message).to be_valid
            expect(message.manifest_process_update_messages.length).to eq(0)
          end
        end
      end

      context 'from nested process attributes' do
        let(:parsed_yaml) do
          {
            'processes' => [{
              'type' => type,
              'command' => command,
              'health-check-type' => health_check_type,
              'health-check-http-endpoint' => health_check_http_endpoint,
              'timeout' => health_check_timeout
            }]
          }
        end

        let(:type) { 'web' }
        let(:command) { 'new-command' }
        let(:health_check_type) { 'http' }
        let(:health_check_http_endpoint) { '/endpoint' }
        let(:health_check_timeout) { 10 }

        context 'when new properties are specified' do
          it 'sets the command and health check type fields in the message' do
            message = AppManifestMessage.create_from_yml(parsed_yaml)
            expect(message).to be_valid
            expect(message.manifest_process_update_messages.length).to eq(1)
            expect(message.manifest_process_update_messages.first.command).to eq('new-command')
            expect(message.manifest_process_update_messages.first.health_check_type).to eq('http')
            expect(message.manifest_process_update_messages.first.health_check_endpoint).to eq('/endpoint')
            expect(message.manifest_process_update_messages.first.health_check_timeout).to eq(10)
          end
        end

        context 'health checks' do
          context 'deprecated health check type none' do
            let(:parsed_yaml) { { "health-check-type": 'none' } }

            it 'is converted to process' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.health_check_type).to eq('process')
            end
          end

          context 'health check timeout without other health check parameters' do
            let(:health_check_timeout) { 10 }
            let(:parsed_yaml) { { "timeout": health_check_timeout } }

            it 'sets the health check timeout in the message' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.health_check_timeout).to eq(10)
            end
          end

          context 'when health check type is http and endpoint is not specified' do
            let(:parsed_yaml) { { 'health-check-type' => 'http' } }

            it 'defaults endpoint to "/"' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.health_check_type).to eq('http')
              expect(message.manifest_process_update_messages.first.health_check_endpoint).to eq('/')
            end
          end

          context 'when health check type is not http and endpoint is not specified' do
            let(:parsed_yaml) { { 'health-check-type' => 'port' } }

            it 'does not default endpoint to "/"' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.health_check_type).to eq('port')
              expect(message.manifest_process_update_messages.first.health_check_endpoint).to be_nil
            end
          end
        end

        context 'command' do
          context 'when command is not requested' do
            let(:parsed_yaml) { { 'processes' => [{ 'type' => 'web' }] } }

            it 'does not set the command field in the process update message' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.requested?(:command)).to be false
            end
          end

          context 'when a string command of value "null" is specified' do
            let(:command) { 'null' }

            it 'does not set the command field in the process update message' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.command).to eq('null')
            end
          end

          # This happens when users specify `command: ` with no value in the manifest.
          context 'when a nil command (value nil) is specified' do
            let(:command) { nil }

            it 'sets the field as null in the process update message' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.command).to eq('null')
            end
          end

          context 'when a default command is specified' do
            let(:command) { 'default' }

            it 'does not set the command field in the process update message' do
              message = AppManifestMessage.create_from_yml(parsed_yaml)
              expect(message).to be_valid
              expect(message.manifest_process_update_messages.length).to eq(1)
              expect(message.manifest_process_update_messages.first.command).to eq('default')
            end
          end

          context 'when processes and app-level process properties are specified' do
            context 'there is a web process type on the process level' do
              let(:parsed_yaml) { { 'command' => 'ignoreme',
                                    'health_check_http_endpoint' => '/not-here',
                                    'health_check_type' => 'http',
                                    'timeout' => 5,
                                    'processes' => [{ 'type' => 'web', 'command' => 'thisone', 'health_check_type' => 'port', 'timeout' => 10 }] }
              }

              it 'uses the values from the web process and ignores the app-level process properties' do
                message = AppManifestMessage.create_from_yml(parsed_yaml)

                expect(message).to be_valid
                expect(message.manifest_process_update_messages.length).to eq(1)
                expect(message.manifest_process_update_messages.first.type).to eq('web')
                expect(message.manifest_process_update_messages.first.command).to eq('thisone')
                expect(message.manifest_process_update_messages.first.health_check_type).to eq('port')
                expect(message.manifest_process_update_messages.first.health_check_http_endpoint).to be_falsey
                expect(message.manifest_process_update_messages.first.timeout).to eq(10)
              end
            end

            context 'there is not a web process type on the process level' do
              let(:parsed_yaml) { { 'command' => 'ignoreme',
                                    'health_check_http_endpoint' => '/not-here',
                                    'health_check_type' => 'http',
                                    'timeout' => 5,
                                    'processes' => [{ 'type' => 'worker', 'command' => 'thisone', 'health_check_type' => 'port', 'timeout' => 10 }] }
              }

              it 'uses the values from the app-level process for the web process' do
                message = AppManifestMessage.create_from_yml(parsed_yaml)

                expect(message).to be_valid
                expect(message.manifest_process_update_messages.length).to eq(2)

                expect(message.manifest_process_update_messages.first.type).to eq('web')
                expect(message.manifest_process_update_messages.first.command).to eq('ignoreme')
                expect(message.manifest_process_update_messages.first.health_check_type).to eq('http')
                expect(message.manifest_process_update_messages.first.health_check_http_endpoint).to eq('/not-here')
                expect(message.manifest_process_update_messages.first.timeout).to eq(5)

                expect(message.manifest_process_update_messages.last.type).to eq('worker')
                expect(message.manifest_process_update_messages.last.command).to eq('thisone')
                expect(message.manifest_process_update_messages.last.health_check_type).to eq('port')
                expect(message.manifest_process_update_messages.last.health_check_http_endpoint).to be_falsey
                expect(message.manifest_process_update_messages.last.timeout).to eq(10)
              end
            end
          end
        end
      end
    end

    describe '#app_update_message' do
      let(:buildpack) { VCAP::CloudController::Buildpack.make }
      let(:stack) { VCAP::CloudController::Stack.make }
      let(:parsed_yaml) { { 'buildpack' => buildpack.name, 'stack' => stack.name } }

      it 'returns an AppUpdateMessage containing mapped attributes' do
        message = AppManifestMessage.create_from_yml(parsed_yaml)

        expect(message.app_update_message.buildpack_data.buildpacks).to include(buildpack.name)
        expect(message.app_update_message.buildpack_data.stack).to eq(stack.name)
      end

      context 'when attributes are not requested in the manifest' do
        context 'when no lifecycle data is requested in the manifest' do
          let(:parsed_yaml) { {} }

          it 'does not forward missing attributes to the AppUpdateMessage' do
            message = AppManifestMessage.create_from_yml(parsed_yaml)

            expect(message.app_update_message.requested?(:lifecycle)).to be false
          end
        end

        context 'when stack is not requested in the manifest but buildpack is requested' do
          let(:parsed_yaml) { { 'buildpack' => buildpack.name } }

          it 'does not forward missing attributes to the AppUpdateMessage' do
            message = AppManifestMessage.create_from_yml(parsed_yaml)

            expect(message.app_update_message.requested?(:lifecycle)).to be true
            expect(message.app_update_message.buildpack_data.requested?(:buildpacks)).to be true
            expect(message.app_update_message.buildpack_data.requested?(:stack)).to be false
          end
        end

        context 'when buildpack is not requested in the manifest but stack is requested' do
          let(:parsed_yaml) { { 'stack' => stack.name } }

          it 'does not forward missing attributes to the AppUpdateMessage' do
            message = AppManifestMessage.create_from_yml(parsed_yaml)

            expect(message.app_update_message.requested?(:lifecycle)).to be true
            expect(message.app_update_message.buildpack_data.requested?(:buildpacks)).to be false
            expect(message.app_update_message.buildpack_data.requested?(:stack)).to be true
          end
        end
      end

      context 'when it specifies a "default" buildpack' do
        let(:parsed_yaml) { { buildpack: 'default' } }
        it 'updates the buildpack_data to be an empty array' do
          message = AppManifestMessage.create_from_yml(parsed_yaml)
          expect(message.app_update_message.buildpack_data.buildpacks).to be_empty
        end
      end

      context 'when it specifies a null buildpack' do
        let(:parsed_yaml) { { buildpack: nil } }
        it 'updates the buildpack_data to be an empty array' do
          message = AppManifestMessage.create_from_yml(parsed_yaml)
          expect(message.app_update_message.buildpack_data.buildpacks).to be_empty
        end
      end
    end

    describe '#app_update_environment_variables_message' do
      let(:parsed_yaml) { { 'env' => { 'foo' => 'bar', 'baz' => 4.44444444444, 'qux' => false } } }

      it 'returns a AppUpdateEnvironmentVariablesMessage containing the env vars' do
        message = AppManifestMessage.create_from_yml(parsed_yaml)
        expect(message).to be_valid
        expect(message.app_update_environment_variables_message.var).
          to eq({ foo: 'bar', baz: '4.44444444444', qux: 'false' })
      end
    end

    describe '#manifest_routes_update_message' do
      let(:parsed_yaml) do
        { 'routes' =>
          [
            { 'route' => 'existing.example.com' }
          ]
        }
      end

      context 'when new properties are specified' do
        it 'sets the routes in the message' do
          message = AppManifestMessage.create_from_yml(parsed_yaml)
          expect(message).to be_valid
          expect(message.manifest_routes_update_message.manifest_routes).to all(be_a(ManifestRoute))
        end
      end

      context 'when no routes are specified' do
        let(:parsed_yaml) do
          {}
        end

        it 'does not set the routes in the message' do
          message = AppManifestMessage.create_from_yml(parsed_yaml)
          expect(message).to be_valid
          expect(message.manifest_routes_update_message.requested?(:routes)).to be_falsey
        end
      end
    end
  end
end
