FactoryGirl.define do
  factory :shipping_method, :class => Spree::ShippingMethod do
    zone { |a| Spree::Zone.find_by_name('GlobalZone') || a.association(:global_zone) }
    name 'UPS Ground'
    calculator { |sm| Factory(:calculator, :calculable_id => sm.object_id, :calculable_type => 'Spree::ShippingMethod') }
  end

  factory :free_shipping_method, :class => Spree::ShippingMethod do
    zone { |a| Spree::Zone.find_by_name('GlobalZone') || a.association(:global_zone) }
    name 'UPS Ground'
    calculator { |sm| Factory(:no_amount_calculator, :calculable_id => sm.object_id, :calculable_type => 'Spree::ShippingMethod') }
  end
end
