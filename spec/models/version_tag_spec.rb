require 'spec_helper'

describe VersionTag do

  describe '#filtered' do

    before(:all) do
      VersionTag.delete_all
      User.current_user = create(:old_user)
      @ins_comp = create(:installed_component)

      @env = create(:environment, :name => 'Staging Environment')
      @app = create(:app, :name => 'Enterprise App')
      @app_env = create(:application_environment, :app => @app, :environment => @env, :installed_components => [@ins_comp])

      @app_comp = create(:application_component, :installed_components => [@ins_comp])
      @comp = create(:component, :name => 'Installed Component', :apps => [@app], :application_components => [@app_comp])

      @vt_1 = create(:version_tag, :name => 'VersionTag 1', :app => @app, :application_environment => @app_env)
      @vt_1a = create(:version_tag, :name => 'VersionTag 1a', :app => @app, :application_environment => @app_env)
      @vt_1a.archive
      @vt_2 = create(:version_tag, :name => 'VersionTag 2', :app => @app, :installed_component => @ins_comp)
      @vt_2a = create(:version_tag, :name => 'VersionTag 2a', :app => @app, :installed_component => @ins_comp)
      @vt_2a.archive
      @vt_3 = create(:version_tag, :name => 'VersionTag 3', :app => @app, :application_environment => @app_env, :installed_component => @ins_comp)
      @vt_3a = create(:version_tag, :name => 'VersionTag 3a', :app => @app, :application_environment => @app_env, :installed_component => @ins_comp)
      @vt_3a.archive
      @vt_4 = create(:version_tag, :name => 'VersionTag 4')
      @vt_4a = create(:version_tag, :name => 'VersionTag 4a')
      @vt_4a.archive
      @vt_4a.reload

      @active = [@vt_1, @vt_2, @vt_3, @vt_4]
      @inactive = [@vt_1a, @vt_2a, @vt_3a, @vt_4a]
    end

    after(:all) do
      VersionTag.delete_all
      ApplicationEnvironment.delete(@app_env)
      App.delete(@app)
      Environment.delete(@env)
      InstalledComponent.delete(@ins_comp)
      ApplicationComponent.delete(@app_comp)
      Component.delete(@comp)
    end

    it_behaves_like 'active/inactive filter' do
      describe 'filter by name' do
        subject { described_class.filtered(:name => 'VersionTag 4') }
        it { should match_array([@vt_4]) }
      end

      describe 'filter by app_name' do
        subject { described_class.filtered(:app_name => 'Enterprise App') }
        it { should match_array([@vt_1, @vt_2, @vt_3]) }
      end

      describe 'filter by component_name' do
        subject { described_class.filtered(:component_name => 'Installed Component') }
        it { should match_array([@vt_2, @vt_3]) }
      end

      describe 'filter by environment_name' do
        subject { described_class.filtered(:environment_name => 'Staging Environment') }
        it { should match_array([@vt_2, @vt_3]) }
      end

      describe 'filter by name, app_name, component_name, environment_name' do
        subject { described_class.filtered(:name => 'VersionTag 3',
                                           :app_name => 'Enterprise App',
                                           :component_name => 'Installed Component',
                                           :environment_name => 'Staging Environment') }
        it { should match_array([@vt_3]) }
      end

      describe 'filter by name (archived is not specified)' do
        subject { described_class.filtered(:name => @vt_4a.name) }
        it { should be_empty }
      end

      describe 'filter by name (archived is specified)' do
        subject { described_class.filtered(:name => @vt_4a.name, :archived => true) }
        it { should match_array([@vt_4a]) }
      end
    end
  end

  protected

  def create_version_tag(options = nil)
    create(:version_tag, options)
  end

end