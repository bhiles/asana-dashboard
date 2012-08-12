require 'spec_helper'


describe Api do
  it "includes bennett's user ID" do
    VCR.use_cassette('synopsis') do
      Api.new.users.map{|entry| entry["id"]}.should include(1349447812794)
    end
  end
end

