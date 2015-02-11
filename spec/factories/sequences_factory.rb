FactoryGirl.define do
  sequence :email do |n|
    # Generating meaningful (thanks to random_data gem) but unique (because of sequences) emails
    Random.email.gsub('@', "#{n}@")
  end
end