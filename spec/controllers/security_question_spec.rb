require 'spec_helper'

describe SecurityQuestionsController, type: :controller do
  it '#new' do
    get :new
    expect(response).to render_template('new')
  end

  context 'create' do
    before(:each) { session[:auth_method] = 'Login' }

    context 'success' do
      specify 'authenticated_via_rpm' do
        User.any_instance.stub(:valid?).and_return(true)

        post :create, {user: { password: 'password1',
                               password_confirmation: 'password1',
                               current_password: 'password1',
                               format: 'js',
                               security_answer: {question_id: '5',
                                                 answer: 'Answer'}},
                               format: 'js'}
        expect(response).to render_template('misc/redirect')
      end
    end

    context 'fails' do
      before(:each) do
        User.stub(:find).and_return(@user)
        @user.stub(:valid?).and_return(false)
      end

      it 'returns security question errors' do
        controller.stub(:current_user_authenticated_via_rpm?).and_return(false)

        post :create, { user: { email: @user.email,
                                first_name: @user.first_name,
                                last_name: @user.last_name },
                        format: 'js' }
        expect(response).to render_template('misc/error_messages_for')
      end

      it 'returns user errors' do
        post :create, { format: 'js',
                        user: { password: 'new_password1',
                                password_confirmation: 'new_password1',
                                current_password: 'password1',
                                security_answer: { question_id: '1',
                                                   answer: 'Answer' }}}
        expect(response).to render_template('misc/error_messages_for')
      end
    end
  end
end