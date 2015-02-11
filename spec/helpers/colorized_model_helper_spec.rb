require "spec_helper"

describe ColorizedModelHelper do
  it "#select_label_color" do
    helper.select_label_color.should include("<option   value='#FAEBD7' style='background-color:#FAEBD7;'>AntiqueWhite</option><option   value='#00FFFF' style='background-color:#00FFFF;'>Aqua</option>")
  end

  it "#selected_color?" do
    helper.selected_color?("#FAEBD7", "#FAEBD7").should eql("selected='yes'")
  end

  it "#colorized_label" do
    helper.colorized_label("#FAEBD7","AntiqueWhite").should include("<span style=\"background:#FAEBD7;")
  end

  it "#colorized_tag_options" do
    helper.colorized_tag_options("#FAEBD7").should eql(" style=\"background: #FAEBD7 none repeat scroll 0 0; color: #000000; border: 1px solid #ccc;\"")
  end

  it "#colorized_label_tag_options" do
    helper.colorized_label_tag_options("#FAEBD7").should eql(" style=\"color: #FAEBD7; font-weight: bold;\"")
  end

  context "#nil_safe_color" do
    it "returns color" do
      helper.nil_safe_color("#FAEBD7").should eql("#FAEBD7")
    end

    it "returns #FFFFFF" do
      helper.nil_safe_color(nil).should eql("#FFFFFF")
    end
  end

  context "#contrasting_font_color" do
    it "returns '#FF0000'" do
      helper.contrasting_font_color(nil).should eql('#FF0000')
    end

    it "returns '#000000'" do
      helper.contrasting_font_color("#FAEBD7").should eql('#000000')
    end

    it "returns '#FFFFFF'" do
      helper.contrasting_font_color("#FF00F5").should eql('#FFFFFF')
    end
  end

  context "#color_safe_border" do
    it "returns '#FF0000'" do
      helper.color_safe_border(nil).should eql('border: 1px dotted #FF0000;')
    end

    it "returns '#000000'" do
      helper.color_safe_border("#FAEBD7").should eql('border: 1px solid #ccc;')
    end

    it "returns '#FFFFFF'" do
      helper.color_safe_border("#FF00F5").should eql("border: 1px solid #FF00F5;")
    end
  end
end