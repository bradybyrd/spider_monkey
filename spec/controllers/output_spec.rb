require 'spec_helper'

describe OutputController, :type => :controller do
  it "#render_output_file" do
    pending "output file is different for each environment"
    get :render_output_file, {:path => 'step/output_1592_1390299199', :format => 'txt'}
    response.body.should include('SCRIPT TO EXECUTE')
  end
end
