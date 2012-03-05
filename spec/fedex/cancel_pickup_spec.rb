require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "FedEx CancelPickup" do
  it "should cancel the pickup" do
    use_response(:cancel_pickup)
    fedex = new_fedex
    cancel = fedex.cancel_pickup(
      :carrier_code => 'FDXG',
      :location => '',
      :confirmation_number => 'CPU220640',
      :scheduled_date => '2012-03-06',
      :remarks => 'test cancellation')
    lambda { cancel.perform }.should_not raise_error
  end
end