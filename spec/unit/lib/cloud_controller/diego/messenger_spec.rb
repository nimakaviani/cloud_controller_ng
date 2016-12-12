require 'spec_helper'
require 'cloud_controller/diego/bbs_stager_client'

module VCAP::CloudController
  module Diego
    RSpec.describe Messenger do
      subject(:messenger) { Messenger.new }

      let(:stager_client) { instance_double(StagerClient) }
      let(:nsync_client) { instance_double(NsyncClient) }
      let(:bbs_stager_client) { instance_double(BbsStagerClient) }
      let(:config) { TestConfig.config }
      let(:protocol) { instance_double(Diego::Protocol) }
      let(:recipe_builder) { instance_double(Diego::RecipeBuilder) }

      before do
        CloudController::DependencyLocator.instance.register(:bbs_stager_client, bbs_stager_client)
        CloudController::DependencyLocator.instance.register(:stager_client, stager_client)
        CloudController::DependencyLocator.instance.register(:nsync_client, nsync_client)
        allow(Diego::Protocol).to receive(:new).and_return(protocol)
        allow(Diego::RecipeBuilder).to receive(:new).and_return(recipe_builder)
      end

      describe '#send_stage_request' do
        let(:package) { PackageModel.make }
        let(:droplet) { DropletModel.make(package: package) }
        let(:staging_guid) { droplet.guid }
        let(:message) { { staging: 'message' } }
        let(:staging_details) do
          VCAP::CloudController::Diego::StagingDetails.new.tap do |sd|
            sd.package = package
            sd.droplet = droplet
          end
        end

        before do
          allow(protocol).to receive(:stage_package_request).and_return(message)
          allow(stager_client).to receive(:stage)
        end

        it 'sends the staging message to the stager' do
          messenger.send_stage_request(config, staging_details)

          expect(protocol).to have_received(:stage_package_request).with(config, staging_details)
          expect(stager_client).to have_received(:stage).with(staging_guid, message)
        end

        context 'when staging local is configured and lifecycle is buildpack' do
          before do
            TestConfig.override(diego: { temporary_local_staging: true })
            staging_details.lifecycle = instance_double(BuildpackLifecycle, type: Lifecycles::BUILDPACK)
            allow(recipe_builder).to receive(:build_staging_task).and_return(message)
            allow(bbs_stager_client).to receive(:stage)
          end

          it 'sends the staging message to the bbs' do
            messenger.send_stage_request(config, staging_details)

            expect(recipe_builder).to have_received(:build_staging_task).with(config, staging_details)
            expect(bbs_stager_client).to have_received(:stage).with(staging_guid, message)
          end
        end
      end

      describe '#send_desire_request' do
        let(:process) { App.new }
        let(:default_health_check_timeout) { 99 }
        let(:process_guid) { ProcessGuid.from_process(process) }
        let(:message) { { desire: 'message' } }
        let(:config) { { default_health_check_timeout: default_health_check_timeout } }

        before do
          allow(protocol).to receive(:desire_app_request).and_return(message)
          allow(nsync_client).to receive(:desire_app)
        end

        it 'sends a desire app request' do
          messenger.send_desire_request(process, config)

          expect(protocol).to have_received(:desire_app_request).with(process, default_health_check_timeout)
          expect(nsync_client).to have_received(:desire_app).with(process_guid, message)
        end

        context 'when configured to start an app directly to diego' do
          let(:bbs_apps_client) { instance_double(BbsAppsClient, desire_app: nil) }
          let(:app_recipe_builder) { instance_double(Diego::AppRecipeBuilder, build_app_lrp: build_lrp) }
          let(:build_lrp) { instance_double(::Diego::Bbs::Models::DesiredLRP) }

          before do
            CloudController::DependencyLocator.instance.register(:bbs_apps_client, bbs_apps_client)
            TestConfig.override(diego: { temporary_local_apps: true })

            allow(protocol).to receive(:desire_app_message).and_return(message)
            allow(Diego::AppRecipeBuilder).to receive(:new).with(config: config, process: process, app_request: message).and_return(app_recipe_builder)
          end

          it 'attempts to create or update the app by delegating to the desire app handler' do
            allow(DesireAppHandler).to receive(:create_or_update_app)
            messenger.send_desire_request(process, config)

            expect(DesireAppHandler).to have_received(:create_or_update_app).with(process_guid, app_recipe_builder, bbs_apps_client)
            expect(protocol).to have_received(:desire_app_message).with(process, default_health_check_timeout)
          end
        end
      end

      describe '#send_stop_staging_request' do
        let(:staging_guid) { 'whatever' }

        before do
          allow(stager_client).to receive(:stop_staging)
        end

        it 'sends a stop_staging request to the stager' do
          messenger.send_stop_staging_request(staging_guid)

          expect(stager_client).to have_received(:stop_staging).with(staging_guid)
        end
      end

      describe '#send_stop_index_request' do
        let(:process) { App.new }
        let(:process_guid) { ProcessGuid.from_process(process) }
        let(:index) { 3 }

        before do
          allow(nsync_client).to receive(:stop_index)
        end

        it 'sends a stop index request' do
          messenger.send_stop_index_request(process, index)

          expect(nsync_client).to have_received(:stop_index).with(process_guid, index)
        end
      end

      describe '#send_stop_app_request' do
        let(:process) { App.new }
        let(:process_guid) { ProcessGuid.from_process(process) }

        before do
          allow(nsync_client).to receive(:stop_app)
        end

        it 'sends a stop app request' do
          messenger.send_stop_app_request(process)

          expect(nsync_client).to have_received(:stop_app).with(process_guid)
        end

        context 'when configured to stop an app directly to diego' do
          let(:bbs_apps_client) { instance_double(BbsAppsClient, stop_app: nil) }

          before do
            CloudController::DependencyLocator.instance.register(:bbs_apps_client, bbs_apps_client)
            TestConfig.override(diego: { temporary_local_apps: true })
          end

          it 'sends a stop app request to the bbs' do
            messenger.send_stop_app_request(process)

            expect(bbs_apps_client).to have_received(:stop_app).with(process_guid)
          end
        end
      end
    end
  end
end