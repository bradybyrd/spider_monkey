require 'spec_helper'

describe StepService::ParamsPerPermissionSanitizer, custom_roles: true do
  describe '#clean_up_params!' do
    context 'when user has all permissions' do
      it 'returns all params' do
        user = build(:user)
        step_hash = sample_step_hash
        user.stub(:cannot?).and_return(false)
        sanizer = StepService::ParamsPerPermissionSanitizer.new(step_hash, build(:request), user)

        sanizer.clean_up_params!
        expect(step_hash).to eq sample_step_hash
      end
    end

    context 'when user has no permissions' do
      it 'has no component_id' do
        user = build(:user)
        step_hash = sample_step_hash
        user.stub(:cannot?).and_return(true)
        sanizer = StepService::ParamsPerPermissionSanitizer.new(step_hash, build(:request), user)

        sanizer.clean_up_params!
        expect(step_hash).to be_empty
      end
    end
  end

  def sample_step_hash
    {
      component_id: 1,
      package_id: 'package',
      step_references: 'references',
      version: 'vesrion',
      own_version: 'own',
      package_instance_id: 1,
      latest_package_instance: 'latest',
      create_new_package_instance: 'create_new'
    }
  end

end
