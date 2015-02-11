require "spec_helper"

describe UploadsController, :type => :controller do
  pending "" do
    before(:each) { @upload = create(:upload) }

    context "#show" do
      specify "with attachment_url and content type" do
        get :show, {:id => @upload.id}
        my_path = File.join(@upload.attachment.root, @upload.attachment_url)
        @data = File.open(my_path, 'rb').read
        response.body.should eql(@data)
        response.header['Content-Type'].should eql 'image/jpeg'
      end

      specify "with relative_path" do
        pending "cann't load file from relative path"
        Upload.stub(:find).and_return(@upload)
        @upload.stub(:attachment_url).and_return('/one')
        get :show, {:id => @upload.id}
        relative_path = ("%08d" % @upload.id).scan(/..../) + [@upload.filename]
        my_path = File.join(@upload.attachment.root, "assets", relative_path)
        @data = File.open(my_path, 'rb').read
        response.body.should eql(@data)
      end

      it "returns error and redirects to back" do
        File.stub(:exist?).and_return(false)
        @request.env["HTTP_REFERER"] = '/index'
        get :show, {:id => @upload.id}
        flash[:error].should include('could not be found')
        response.should redirect_to('/index')
      end
    end

    context "#destroy" do
      it "upload of request" do
        @request1 = create(:request)
        @request1.uploads << @upload
        expect{delete :destroy, {:id => @upload.id,
                                 :request_id => @request1.id}
              }.to change(Upload, :count).by(-1)
        response.should render_template(:partial => "_update_uploads")
      end

      it "upload of activity" do
        @request.env["HTTP_REFERER"] = '/index'
        @activity = create(:activity)
        @activity.uploads << @upload
        expect{delete :destroy, {:id => @upload.id,
                                 :activity_id => @activity.id}
              }.to change(Upload, :count).by(-1)
        response.should redirect_to('/index')
      end

      it "upload of step" do
        @request1 = create(:request)
        @step = create(:step, :request => @request1)
        @step.uploads << @upload
        expect{delete :destroy, {:id => @upload.id,
                                 :step_id => @step.id}
              }.to change(Upload, :count).by(-1)
        response.should render_template(:partial => "steps/step_rows/_update_uploads")
      end
    end
  end
end