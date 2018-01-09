require 'spec_helper'

module VCAP::CloudController
  RSpec.describe ServiceKeyAccess, type: :access do
    let(:access_context) { Security::AccessContext.new(VCAP::CloudController::Permissions::SecurityContextQueryer.new) }
    subject(:access) { ServiceKeyAccess.new(access_context) }
    let(:scopes) { ['cloud_controller.read', 'cloud_controller.write'] }
    let(:user) { VCAP::CloudController::User.make }
    let(:service) { VCAP::CloudController::Service.make }
    let(:org) { VCAP::CloudController::Organization.make }
    let(:space) { VCAP::CloudController::Space.make(organization: org) }
    let(:service_instance) { VCAP::CloudController::ManagedServiceInstance.make(space: space) }

    let(:object) { VCAP::CloudController::ServiceKey.make(name: 'fake-key', service_instance: service_instance) }

    before { set_current_user(user, scopes: scopes) }

    it_behaves_like :admin_full_access
    it_behaves_like :admin_read_only_access

    context 'admin' do
      include_context :admin_setup

      context 'without related obj' do
        it { is_expected.to allow_op_on_object(:index, object) }
      end

      context 'with related obj' do
        it { is_expected.to allow_op_on_object(:index, object, { related_obj: service_instance }) }
      end
    end

    context 'read-only admin' do
      include_context :admin_read_only_setup

      context 'without related obj' do
        it { is_expected.to allow_op_on_object(:index, object) }
      end

      context 'with related obj' do
        it { is_expected.to allow_op_on_object(:index, object, { related_obj: service_instance }) }
      end
    end

    context 'global auditor' do
      include_context :global_auditor_setup

      context 'without related obj' do
        it { is_expected.to allow_op_on_object(:index, object) }
      end

      context 'with related obj' do
        it { is_expected.not_to allow_op_on_object(:index, object, { related_obj: service_instance }) }
      end
    end

    context 'for a logged in user (defensive)' do
      it_behaves_like :no_access

      it { is_expected.not_to allow_op_on_object(:read_env, object) }

      context 'without related obj' do
        it { is_expected.to allow_op_on_object(:index, object) }
      end

      context 'with related obj' do
        it { is_expected.not_to allow_op_on_object(:index, object, { related_obj: service_instance }) }
      end
    end

    context "a user that isn't logged in (defensive)" do
      let(:user) { nil }

      it_behaves_like :no_access

      it { is_expected.not_to allow_op_on_object(:read_env, object) }

      context 'without related obj' do
        it { is_expected.to allow_op_on_object(:index, object) }
      end

      context 'with related obj' do
        it { is_expected.not_to allow_op_on_object(:index, object, { related_obj: service_instance }) }
      end
    end

    context 'organization manager (defensive)' do
      before { org.add_manager(user) }

      it_behaves_like :no_access

      it { is_expected.not_to allow_op_on_object(:read_env, object) }

      context 'without related obj' do
        it { is_expected.to allow_op_on_object(:index, object) }
      end

      context 'with related obj' do
        it { is_expected.not_to allow_op_on_object(:index, object, { related_obj: service_instance }) }
      end
    end

    context 'organization billing manager (defensive)' do
      before { org.add_billing_manager(user) }

      it_behaves_like :no_access

      it { is_expected.not_to allow_op_on_object(:read_env, object) }

      context 'without related obj' do
        it { is_expected.to allow_op_on_object(:index, object) }
      end

      context 'with related obj' do
        it { is_expected.not_to allow_op_on_object(:index, object, { related_obj: service_instance }) }
      end
    end

    context 'organization auditor (defensive)' do
      before { org.add_auditor(user) }

      it_behaves_like :no_access

      it { is_expected.not_to allow_op_on_object(:read_env, object) }

      context 'without related obj' do
        it { is_expected.to allow_op_on_object(:index, object) }
      end

      context 'with related obj' do
        it { is_expected.not_to allow_op_on_object(:index, object, { related_obj: service_instance }) }
      end
    end

    context 'organization user (defensive)' do
      before { org.add_user(user) }

      it_behaves_like :no_access

      it { is_expected.not_to allow_op_on_object(:read_env, object) }

      context 'without related obj' do
        it { is_expected.to allow_op_on_object(:index, object) }
      end

      context 'with related obj' do
        it { is_expected.not_to allow_op_on_object(:index, object, { related_obj: service_instance }) }
      end
    end

    context 'space auditor' do
      before do
        org.add_user(user)
        space.add_auditor(user)
      end

      it_behaves_like :no_access

      it { is_expected.not_to allow_op_on_object(:read_env, object) }

      context 'without related obj' do
        it { is_expected.to allow_op_on_object(:index, object) }
      end

      context 'with related obj' do
        it { is_expected.not_to allow_op_on_object(:index, object, { related_obj: service_instance }) }
      end
    end

    context 'space manager (defensive)' do
      before do
        org.add_user(user)
        space.add_manager(user)
      end

      it_behaves_like :no_access

      it { is_expected.not_to allow_op_on_object(:read_env, object) }

      context 'without related obj' do
        it { is_expected.to allow_op_on_object(:index, object) }
      end

      context 'with related obj' do
        it { is_expected.not_to allow_op_on_object(:index, object, { related_obj: service_instance }) }
      end
    end

    context 'space developer' do
      before do
        org.add_user(user)
        space.add_developer(user)
      end

      it { is_expected.to allow_op_on_object :create, object }
      it { is_expected.to allow_op_on_object :read, object }
      it { is_expected.not_to allow_op_on_object :read_for_update, object }
      it { is_expected.to allow_op_on_object :delete, object }
      it { is_expected.to allow_op_on_object(:read_env, object) }

      context 'when the organization is suspended' do
        before { allow(object).to receive(:in_suspended_org?).and_return(true) }

        it_behaves_like :read_only_access
      end

      context 'without related obj' do
        it { is_expected.to allow_op_on_object(:index, object) }
      end

      context 'with related obj' do
        it { is_expected.to allow_op_on_object(:index, object, { related_obj: service_instance }) }
      end
    end

    context 'any user using client without cloud_controller.write' do
      let(:scopes) { ['cloud_controller.read'] }

      before do
        org.add_user(user)
        org.add_manager(user)
        org.add_billing_manager(user)
        org.add_auditor(user)
        space.add_manager(user)
        space.add_developer(user)
        space.add_auditor(user)
      end

      it_behaves_like :read_only_access

      context 'without related obj' do
        it { is_expected.to allow_op_on_object(:index, object) }
      end

      context 'with related obj' do
        it { is_expected.to allow_op_on_object(:index, object, { related_obj: service_instance }) }
      end
    end

    context 'any user using client without cloud_controller.read' do
      let(:scopes) { [] }

      before do
        org.add_user(user)
        org.add_manager(user)
        org.add_billing_manager(user)
        org.add_auditor(user)
        space.add_manager(user)
        space.add_developer(user)
        space.add_auditor(user)
      end

      it_behaves_like :no_access

      context 'without related obj' do
        it { is_expected.to allow_op_on_object(:index, object) }
      end

      context 'with related obj' do
        it { is_expected.to allow_op_on_object(:index, object, { related_obj: service_instance }) }
      end
    end
  end
end
