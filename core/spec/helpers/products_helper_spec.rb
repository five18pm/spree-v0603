require 'spec_helper'


module Spree
  describe ProductsHelper do
    include ProductsHelper
    include BaseHelper
    context "#product_price" do
      before do
        reset_spree_preferences
      end

      let!(:tax_category) { Factory(:tax_category) }
      let!(:product) { Factory(:product, :tax_category => tax_category) }

      it "shows a product's price" do
      reset_spree_preferences do |config|
        config.show_price_inc_vat = false
      end
        product_price(product).should == "$19.99"
      end

      it "shows a product's price including tax" do
        pending "Broken on the CI server, but not on dev machines. To be investigated later."
        product.stub :tax_category => tax_category
        tax_category.stub :effective_amount => BigDecimal.new("0.05", 2)
        Spree::Config.set :show_price_inc_vat => true
        product_price(product).should == "$20.99 (inc. VAT)"
      end

    end
  end
end
