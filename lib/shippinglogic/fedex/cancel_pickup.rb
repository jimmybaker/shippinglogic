require "base64"
module Shippinglogic
  class FedEx

    class CancelPickup < Service
      class CancelledPickup; end
      VERSION = {:major => 3, :intermediate => 0, :minor => 0}

      attribute :customer_transaction_id,     :string,      :default => 'Taigan_Pickup_Cancellation'
      attribute :carrier_code,                :string
      attribute :confirmation_number,         :string
      attribute :location,                    :string
      attribute :scheduled_date,              :string
      attribute :remarks,                     :string
      attribute :log,                         :string

      private
      def target
        @target ||= parse_response(request(build_request))
      end

      def build_request
        b = builder
        xml = b.tag!("CancelPickupRequest", :xmlns => "http://fedex.com/ws/pickup/v#{VERSION[:major]}") do
          build_authentication(b)
          build_version(b, "disp", VERSION[:major], VERSION[:intermediate], VERSION[:minor])
          b.CarrierCode carrier_code
          b.PickupConfirmationNumber confirmation_number
          b.ScheduledDate scheduled_date
          if location && location.length > 0
            b.Location location
          end
          b.Remarks remarks
        end
      end

      def parse_response(response)
        cp = CancelledPickup.new
        cp
      end
    end
  end
end