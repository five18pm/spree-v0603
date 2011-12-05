require 'spec_helper'

describe "Promotion Adjustments" do
  context "coupon promotions", :js => true do
    before(:each) do
      PAYMENT_STATES = Spree::Payment.state_machine.states.keys unless defined? PAYMENT_STATES
      SHIPMENT_STATES = Spree::Shipment.state_machine.states.keys unless defined? SHIPMENT_STATES
      ORDER_STATES = Spree::Order.state_machine.states.keys unless defined? ORDER_STATES
      Factory(:bogus_payment_method, :environment => 'test')

      Factory(:shipping_method, :zone => Spree::Zone.find_by_name('North America'))
      user = Factory(:admin_user)
      Factory(:product, :name => "RoR Mug", :price => "40")
      Factory(:product, :name => "RoR Bag", :price => "20")

      sign_in_as!(user)
      visit spree.admin_path
      click_link "Promotions"
      click_link "New Promotion"
    end

    let!(:address) { Factory(:address, :state => Spree::State.first) }

    it "should allow an admin to create a flat rate discount coupon promo" do
      fill_in "Name", :with => "Order's total > $30"
      fill_in "Usage Limit", :with => "100"
      select "Coupon code added", :with => "Event"
      fill_in "Code", :with => "ORDER_38"
      click_button "Create"
      page.should have_content("Editing Promotion")

      select "Item total", :from => "Add rule of type"
      within('#rule_fields') { click_button "Add" }
      fill_in "Order total meets these criteria", :with => "30"
      within('#rule_fields') { click_button "Update" }

      select "Create adjustment", :from => "Add action of type"
      within('#action_fields') { click_button "Add" }
      select "Flat Rate (per order)", :from => "Calculator"
      within('#actions_container') { click_button "Update" }
      within('.calculator-fields') { fill_in "Amount", :with => "5" }
      within('#actions_container') { click_button "Update" }

      visit spree.root_path
      click_link "RoR Mug"
      click_button "Add To Cart"
      click_link "Checkout"

      str_addr = "bill_address"
      select "United States", :from => "order_#{str_addr}_attributes_country_id"
      ['firstname', 'lastname', 'address1', 'city', 'zipcode', 'phone'].each do |field|
        fill_in "order_#{str_addr}_attributes_#{field}", :with => "#{address.send(field)}"
      end
      select "#{address.state.name}", :from => "order_#{str_addr}_attributes_state_id"
      check "order_use_billing"
      click_button "Save and Continue"
      click_button "Save and Continue"
      fill_in "order_coupon_code", :with => "ORDER_38"
      click_button "Save and Continue"
      Spree::Order.first.total.to_f.should == 52.00
    end

    it "should allow an admin to create a single user coupon promo with flat rate discount" do
      fill_in "Name", :with => "Order's total > $30"
      fill_in "Usage Limit", :with => "1"
      select "Coupon code added", :from => "Event"
      fill_in "Code", :with => "SINGLE_USE"
      click_button "Create"
      page.should have_content("Editing Promotion")

      select "Item total", :from => "Add rule of type"
      within('#rule_fields') { click_button "Add" }
      fill_in "Order total meets these criteria", :with => "30"
      within('#rule_fields') { click_button "Update" }

      select "Create adjustment", :from => "Add action of type"
      within('#action_fields') { click_button "Add" }
      select "Flat Rate (per order)", :from => "Calculator"
      within('#actions_container') { click_button "Update" }
      within('#action_fields') { fill_in "Amount", :with => "5" }
      within('#actions_container') { click_button "Update" }

      visit spree.root_path
      click_link "RoR Mug"
      click_button "Add To Cart"
      click_link "Checkout"

      str_addr = "bill_address"
      select "United States", :from => "order_#{str_addr}_attributes_country_id"
      ['firstname', 'lastname', 'address1', 'city', 'zipcode', 'phone'].each do |field|
        fill_in "order_#{str_addr}_attributes_#{field}", :with => "#{address.send(field)}"
      end
      select "#{address.state.name}", :from => "order_#{str_addr}_attributes_state_id"
      check "order_use_billing"
      click_button "Save and Continue"
      click_button "Save and Continue"
      fill_in "order_coupon_code", :with => "SINGLE_USE"
      click_button "Save and Continue"
      Spree::Order.first.total.to_f.should == 52.00

      user = Factory(:user, :email => "john@test.com", :password => "secret", :password_confirmation => "secret")
      click_link "Logout"
      click_link "Log In"
      fill_in "user_email", :with => user.email
      fill_in "user_password", :with => user.password
      click_button "Log In"

      visit spree.root_path
      click_link "RoR Mug"
      click_button "Add To Cart"
      click_link "Checkout"

      str_addr = "bill_address"
      select "United States", :from => "order_#{str_addr}_attributes_country_id"
      ['firstname', 'lastname', 'address1', 'city', 'zipcode', 'phone'].each do |field|
        fill_in "order_#{str_addr}_attributes_#{field}", :with => "#{address.send(field)}"
      end
      select "#{address.state.name}", :from => "order_#{str_addr}_attributes_state_id"
      check "order_use_billing"
      click_button "Save and Continue"
      click_button "Save and Continue"
      fill_in "order_coupon_code", :with => "SINGLE_USE"
      click_button "Save and Continue"
      Spree::Order.last.total.to_f.should == 52.00
    end

    it "should allow an admin to create an automatic promo with flat percent discount" do
      pending("TODO: cmar to look at this regarding #831")
      fill_in "Name", :with => "Order's total > $30"
      fill_in "Code", :with => ""
      select "Order contents changed", :from => "Event"
      click_button "Create"
      page.should have_content("Editing Promotion")

      select "Item total", :from => "Add rule of type"
      within('#rule_fields') { click_button "Add" }
      fill_in "Order total meets these criteria", :with => "30"
      within('#rule_fields') { click_button "Update" }

      select "Create adjustment", :from => "Add action of type"
      within('#action_fields') { click_button "Add" }
      select "Flat Percent", :from => "Calculator"
      within('#actions_container') { click_button "Update" }
      within('.calculator-fields') { fill_in "Flat Percent", :with => "10" }
      within('#actions_container') { click_button "Update" }

      visit spree.root_path
      click_link "RoR Mug"
      click_button "Add To Cart"
      Spree::Order.last.total.to_f.should == 36.00
      visit spree.root_path
      click_link "RoR Bag"
      click_button "Add To Cart"
      Spree::Order.last.total.to_f.should == 54.00
    end

    it "should allow an admin to create an automatic promotion with free shipping" do
      pending("TODO: cmar to look at this regarding #831")
      fill_in "Name", :with => "Free Shipping"
      fill_in "Code", :with => ""
      click_button "Create"
      page.should have_content("Editing Promotion")

      select "Item total", :from => "Add rule of type"
      within('#rule_fields') { click_button "Add" }
      fill_in "Order total meets these criteria", :with => "30"
      within('#rule_fields') { click_button "Update" }

      select "Create adjustment", :from => "Add action of type"
      within('#action_fields') { click_button "Add" }
      select "Free Shipping", :from => "Calculator"
      within('#actions_container') { click_button "Update" }

      visit spree.root_path
      click_link "RoR Bag"
      click_button "Add To Cart"
      click_link "Checkout"

      str_addr = "bill_address"
      select "United States", :from => "order_#{str_addr}_attributes_country_id"
      ['firstname', 'lastname', 'address1', 'city', 'zipcode', 'phone'].each do |field|
        fill_in "order_#{str_addr}_attributes_#{field}", :with => "#{address.send(field)}"
      end
      select "#{address.state.name}", :from => "order_#{str_addr}_attributes_state_id"
      check "order_use_billing"
      click_button "Save and Continue"
      click_button "Save and Continue"
      click_button "Save and Continue"
      Spree::Order.last.total.to_f.should == 31.00
      page.should_not have_content("Free Shipping")

      visit spree.root_path
      click_link "RoR Mug"
      click_button "Add To Cart"
      click_link "Checkout"

      str_addr = "bill_address"
      select "United States", :from => "order_#{str_addr}_attributes_country_id"
      ['firstname', 'lastname', 'address1', 'city', 'zipcode', 'phone'].each do |field|
        fill_in "order_#{str_addr}_attributes_#{field}", :with => "#{address.send(field)}"
      end
      select "#{address.state.name}", :from => "order_#{str_addr}_attributes_state_id"
      check "order_use_billing"
      click_button "Save and Continue"
      click_button "Save and Continue"
      click_button "Save and Continue"
      Spree::Order.last.total.to_f.should == 63.00
      page.should have_content("Free Shipping")
    end

    it "should allow an admin to create an automatic promo requiring a landing page to be visited" do
      pending("TODO: cmar to look at this regarding #831")
      fill_in "Name", :with => "Deal"
      select "Order contents changed", :from => "Event"
      click_button "Create"
      page.should have_content("Editing Promotion")

      select "Landing Page", :from => "Add rule of type"
      within('#rule_fields') { click_button "Add" }
      fill_in "Path", :with => "cvv"
      within('#rule_fields') { click_button "Update" }

      select "Create adjustment", :from => "Add action of type"
      within('#action_fields') { click_button "Add" }
      select "Flat Rate (per order)", :from => "Calculator"
      within('#actions_container') { click_button "Update" }
      within('.calculator-fields') { fill_in "Amount", :with => "4" }
      within('#actions_container') { click_button "Update" }

      visit spree.root_path
      click_link "RoR Mug"
      click_button "Add To Cart"
      Spree::Order.last.total.to_f.should == 40.00

      visit "/cvv"
      visit spree.root_path
      click_link "RoR Mug"
      click_button "Add To Cart"
      Spree::Order.last.total.to_f.should == 76.00
    end

    it "ceasing to be eligible for a promotion with item total rule then becoming eligible again" do
      pending("TODO: cmar to look at this regarding #831")

      fill_in "Name", :with => "Spend over $50 and save $5"
      select "Order contents changed", :from => "Event"
      click_button "Create"
      page.should have_content("Editing Promotion")

      select "Item total", :from => "Add rule of type"
      within('#rule_fields') { click_button "Add" }
      fill_in "Order total meets these criteria", :with => "50"
      within('#rule_fields') { click_button "Update" }

      select "Create adjustment", :from => "Add action of type"
      within('#action_fields') { click_button "Add" }
      select "Flat Rate (per order)", :from => "Calculator"
      within('#actions_container') { click_button "Update" }
      within('.calculator-fields') { fill_in "Amount", :with => "5" }
      within('#actions_container') { click_button "Update" }

      visit spree.root_path
      click_link "RoR Bag"
      click_button "Add To Cart"
      Spree::Order.last.total.to_f.should == 20.00

      fill_in "order[line_items_attributes][0][quantity]", :with => "2"
      click_button "Update"
      Spree::Order.last.total.to_f.should == 40.00
      Spree::Order.last.adjustments.promotion.count.should == 0

      fill_in "order[line_items_attributes][0][quantity]", :with => "3"
      click_button "Update"
      Spree::Order.last.total.to_f.should == 55.00
      Spree::Order.last.adjustments.promotion.count.should == 1

      fill_in "order[line_items_attributes][0][quantity]", :with => "2"
      click_button "Update"
      Spree::Order.last.total.to_f.should == 40.00
      Spree::Order.last.adjustments.promotion.count.should == 1

      fill_in "order[line_items_attributes][0][quantity]", :with => "3"
      click_button "Update"
      Spree::Order.last.total.to_f.should == 55.00
    end

    it "only counting the most valuable promotion adjustment in an order" do
      pending("TODO: cmar to look at this regarding #831")
      fill_in "Name", :with => "$5 off"
      select "Order contents changed", :from => "Event"
      click_button "Create"
      page.should have_content("Editing Promotion")
      select "Create adjustment", :from => "Add action of type"
      within('#action_fields') { click_button "Add" }
      select "Flat Rate (per order)", :from => "Calculator"
      within('#actions_container') { click_button "Update" }
      within('.calculator-fields') { fill_in "Amount", :with => "5" }
      within('#actions_container') { click_button "Update" }

      visit spree.admin_promotions_path
      click_link "New Promotion"
      fill_in "Name", :with => "10% off"
      select "Order contents changed", :from => "Event"
      click_button "Create"
      page.should have_content("Editing Promotion")
      select "Create adjustment", :from => "Add action of type"
      within('#action_fields') { click_button "Add" }
      select "Flat Percent", :from => "Calculator"
      within('#actions_container') { click_button "Update" }
      within('.calculator-fields') { fill_in "Flat Percent", :with => "10" }
      within('#actions_container') { click_button "Update" }

      visit spree.root_path
      click_link "RoR Bag"
      click_button "Add To Cart"
      Spree::Order.last.total.to_f.should == 15.00
      Spree::Order.last.adjustments.promotion.count.should == 2

      fill_in "order[line_items_attributes][0][quantity]", :with => "2"
      click_button "Update"
      Spree::Order.last.total.to_f.should == 35.00

      fill_in "order[line_items_attributes][0][quantity]", :with => "3"
      click_button "Update"
      Spree::Order.last.total.to_f.should == 54.00
    end
  end
end
