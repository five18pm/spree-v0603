require 'spec_helper'

describe Spree::User do

  context "validation" do
    it { should have_valid_factory(:user) }
  end

end
