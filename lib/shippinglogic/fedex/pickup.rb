require "base64"
module Shippinglogic
  class FedEx

    class Pickup < Service
      class ScheduledPickup; attr_accessor :customer_transaction_id, :confirmation_number, :location; end
      VERSION = {:major => 3, :intermediate => 0, :minor => 0}

      # pickup options
      attribute :customer_transaction_id,     :string,      :default => 'Taigan_Pickup'

      # contact info
      attribute :name,                :string
      attribute :company_name,        :string
      attribute :phone_number,        :string


      # attribute :email,               :string

      # pickup location
      attribute :streets,                     :array,       :default => []
      attribute :city,                        :string
      attribute :state,                       :string
      attribute :postal_code,                 :string
      attribute :country,                     :string
      attribute :residential,                 :boolean,     :default => false
      attribute :use_account_address,         :boolean,     :default => false         # Set to true to only check the availability of pickup service
      attribute :package_location,            :string,      :default => 'NONE'        # Valid values: FRONT, NONE, REAR, SIDE
      attribute :building_part,               :string,      :default => 'BUILDING'    # Valid values: APARTMENT, BUILDING, DEPARTMENT, FLOOR, ROOM, SUITE
      attribute :building_part_description,   :string
      attribute :ready_timestamp,             :string
      attribute :company_close_time,          :string
      attribute :package_count,               :integer,     :default => 1
      attribute :total_weight,                :float,       :default => 1.0
      attribute :total_weight_units,          :string,      :default => 'LB'
      attribute :carrier_code,                :string,      :default => 'FDXG'
      attribute :remarks,                     :string       # Max length: 60 characters
      attribute :log,                         :string
      attribute :check_availability,          :boolean,     :default => false
      attribute :commodity_description,       :string

      private
      def target
        @target ||= parse_response(request(build_request))
      end

      def build_request
        b = builder
        xml = b.tag!(check_availability ? "PickupAvailabilityRequest" : "CreatePickupRequest", :xmlns => "http://fedex.com/ws/pickup/v#{VERSION[:major]}") do
          build_authentication(b)
          build_version(b, "disp", VERSION[:major], VERSION[:intermediate], VERSION[:minor])
          b.OriginDetail do
            b.PickupLocation do
              b.Contact do
                b.PersonName name
                b.CompanyName company_name
                b.PhoneNumber phone_number
              end
              b.Address do
                b.StreetLines streets.join('\n')
                b.City city
                b.StateOrProvinceCode state
                b.PostalCode postal_code
                b.CountryCode country
                b.Residential residential
              end
            end
            b.PackageLocation package_location
            b.BuildingPart building_part
            b.BuildingPartDescription building_part_description
            b.ReadyTimestamp ready_timestamp #.strftime("%Y-%m-%dT%H:%M:%S")
            b.CompanyCloseTime company_close_time #.strftime("%Y-%m-%dT%H:%M:%S")
          end
          b.PackageCount package_count
          b.TotalWeight do
            b.Units total_weight_units
            b.Value total_weight
          end
          b.CarrierCode carrier_code
          b.Remarks remarks
          b.CommodityDescription commodity_description
        end
      end

      def parse_response(response)
        sp = ScheduledPickup.new
        sp.customer_transaction_id = response[:transaction_detail][:customer_transaction_id]
        sp.confirmation_number = response[:pickup_confirmation_number]
        sp.location = response[:location]
        sp
      end

    end
  end
end
