require "base64"

module Shippinglogic
  class FedEx
    # An interface to the shipe services provided by FedEx. Allows you to create shipments and get various information on the shipment
    # created. Such as the tracking number, the label image, barcode image, delivery date, etc.
    #
    # == Options
    # === Shipper options
    #
    # * <tt>shipper_name</tt> - name of the shipper.
    # * <tt>shipper_title</tt> - title of the shipper.
    # * <tt>shipper_company_name</tt> - company name of the shipper.
    # * <tt>shipper_phone_number</tt> - phone number of the shipper.
    # * <tt>shipper_email</tt> - email of the shipper.
    # * <tt>shipper_streets</tt> - street part of the address, separate multiple streets with a new line, dont include blank lines.
    # * <tt>shipper_city</tt> - city part of the address.
    # * <tt>shipper_state_</tt> - state part of the address, use state abreviations.
    # * <tt>shipper_postal_code</tt> - postal code part of the address. Ex: zip for the US.
    # * <tt>shipper_country</tt> - country code part of the address. FedEx expects abbreviations, but Shippinglogic will convert full names to abbreviations for you.
    # * <tt>shipper_residential</tt> - a boolean value representing if the address is redential or not (default: false)
    #
    # === Recipient options
    #
    # * <tt>recipient_name</tt> - name of the recipient.
    # * <tt>recipient_title</tt> - title of the recipient.
    # * <tt>recipient_company_name</tt> - company name of the recipient.
    # * <tt>recipient_phone_number</tt> - phone number of the recipient.
    # * <tt>recipient_email</tt> - email of the recipient.
    # * <tt>recipient_streets</tt> - street part of the address, separate multiple streets with a new line, dont include blank lines.
    # * <tt>recipient_city</tt> - city part of the address.
    # * <tt>recipient_state</tt> - state part of the address, use state abreviations.
    # * <tt>recipient_postal_code</tt> - postal code part of the address. Ex: zip for the US.
    # * <tt>recipient_country</tt> - country code part of the address. FedEx expects abbreviations, but Shippinglogic will convert full names to abbreviations for you.
    # * <tt>recipient_residential</tt> - a boolean value representing if the address is redential or not (default: false)
    #
    # === Label options
    #
    # * <tt>label_format</tt> - one of Enumerations::LABEL_FORMATS. (default: COMMON2D)
    # * <tt>label_file_type</tt> - one of Enumerations::LABEL_FILE_TYPES. (default: PDF)
    # * <tt>label_stock_type</tt> - one of Enumerations::LABEL_STOCK_TYPES. (default: PAPER_8.5X11_TOP_HALF_LABEL)
    #
    # === Packaging options
    #
    # One thing to note is that FedEx does support multiple package shipments. The problem is that all of the packages must be identical.
    # FedEx specifically notes in their documentation that mutiple package specifications are not allowed. So your only option for a
    # multi package shipment is to increase the package_count option and keep the dimensions and weight the same for all packages. Then again,
    # the documentation for the FedEx web services is terrible, so I could be wrong. Any tests I tried resulted in an error though.
    #
    # * <tt>packaging_type</tt> - one of Enumerations::PACKAGE_TYPES. (default: YOUR_PACKAGING)
    # * <tt>package_count</tt> - the number of packages in your shipment. (default: 1)
    # * <tt>package_weight</tt> - a single packages weight.
    # * <tt>package_weight_units</tt> - either LB or KG. (default: LB)
    # * <tt>package_length</tt> - a single packages length, only required if using YOUR_PACKAGING for packaging_type.
    # * <tt>package_width</tt> - a single packages width, only required if using YOUR_PACKAGING for packaging_type.
    # * <tt>package_height</tt> - a single packages height, only required if using YOUR_PACKAGING for packaging_type.
    # * <tt>package_dimension_units</tt> - either IN or CM. (default: IN)
    #
    # === Monetary options
    #
    # * <tt>currency_type</tt> - the type of currency. (default: nil, because FedEx will default to your account preferences)
    # * <tt>insured_value</tt> - the value you want to insure, if any. (default: nil)
    # * <tt>payment_type</tt> - one of Enumerations::PAYMENT_TYPES. (default: SENDER)
    # * <tt>payor_account_number</tt> - if the account paying for this ship is different than the account you specified then
    #   you can specify that here. (default: your account number)
    # * <tt>payor_country</tt> - the country code for the account number. (default: US)
    #
    # === Delivery options
    #
    # * <tt>ship_time</tt> - a Time object representing when you want to ship the package. (default: Time.now)
    # * <tt>service_type</tt> - one of Enumerations::SERVICE_TYPES, this is optional, leave this blank if you want a list of all
    #   available services. (default: nil)
    # * <tt>dropoff_type</tt> - one of Enumerations::DROP_OFF_TYPES. (default: REGULAR_PICKUP)
    # * <tt>special_services_requested</tt> - any exceptions or special services FedEx needs to be aware of, this should be
    #   one or more of Enumerations::SPECIAL_SERVICES. (default: nil)
    # * <tt>signature</tt> - one of Enumerations::SIGNATURE_OPTION_TYPES. (default: nil, which defaults to the service default)
    #
    # === Misc options
    #
    # * <tt>just_validate</tt> - will tell FedEx to ONLY validate the shipment, not actually create it. (default: false)
    # * <tt>rate_request_types</tt> - one or more of Enumerations::RATE_REQUEST_TYPES. (default: ACCOUNT)
    #
    # == Simple Example
    #
    # Here is a very simple example. Mix and match the options above to get more accurate rates:
    #
    #   fedex = Shippinglogic::FedEx.new(key, password, account, meter)
    #   shipment = fedex.ship(
    #     :shipper_postal_code => "10007",
    #     :shipper_country => "US",
    #     :recipient_postal_code => "75201",
    #     :recipient_country_code => "US",
    #     :package_weight => 24,
    #     :package_length => 12,
    #     :package_width => 12,
    #     :package_height => 12
    #   )
    #
    #   shipment.inspect
    #   #<Shippinglogic::FedEx::Ship::Shipment rate:decimal, currency:string, delivery_date:date, tracking_number:string,
    #     label:string(base64 decoded), barcode:string(base64 decoded) >
    #   
    #   # to show accessor methods
    #   shipment.tracking_number
    #   # => "XXXXXXXXXXXXXX"
    class Ship < Service
      # The shipment result is an object of this class
      class Shipment; attr_accessor :rate, :currency, :delivery_date, :tracking_number, :label, :barcode, :tracking_numbers; end
      
      VERSION = {:major => 9, :intermediate => 0, :minor => 0}
      
      # shipper options
      attribute :shipper_name,                :string
      attribute :shipper_title,               :string
      attribute :shipper_company_name,        :string
      attribute :shipper_phone_number,        :string
      attribute :shipper_email,               :string
      attribute :shipper_streets,             :array,       :default => []
      attribute :shipper_city,                :string
      attribute :shipper_state,               :string
      attribute :shipper_postal_code,         :string
      attribute :shipper_country,             :string
      attribute :shipper_residential,         :boolean,     :default => false
      
      # recipient options
      attribute :recipient_name,              :string
      attribute :recipient_title,             :string
      attribute :recipient_company_name,      :string
      attribute :recipient_phone_number,      :string
      attribute :recipient_email,             :string
      attribute :recipient_streets,           :array,       :default => []
      attribute :recipient_city,              :string
      attribute :recipient_state,             :string
      attribute :recipient_postal_code,       :string
      attribute :recipient_country,           :string
      attribute :recipient_residential,       :boolean,     :default => false
      
      # label options
      attribute :label_format,                :string,      :default => "COMMON2D"
      attribute :label_file_type,             :string,      :default => "PDF"
      attribute :label_stock_type,            :string,      :default => "PAPER_7X4.75"
      
      # packaging options
      attribute :packaging_type,              :string,      :default => "YOUR_PACKAGING"
      attribute :package_count,               :integer,     :default => 1
      attribute :package_detail,              :string,      :default => "INDIVIDUAL_PACKAGES"
      attribute :package_weight,              :float
      attribute :package_weight_units,        :string,      :default => "LB"
      attribute :package_length,              :integer
      attribute :package_width,               :integer
      attribute :package_height,              :integer
      attribute :package_dimension_units,     :string,      :default => "IN"
      
      # customer references
      attribute :invoice_number,              :string,      :default => ''
      attribute :po_number,                   :string,      :default => ''
      attribute :customer_reference_number,   :string,      :default => ''
      attribute :department_number,           :string,      :default => ''
      attribute :ship_id,                     :string,      :default => ''

      # monetary options
      attribute :currency_type,               :string
      attribute :insured_value,               :decimal
      attribute :payment_type,                :string,      :default => "SENDER"
      attribute :payor_account_number,        :string,      :default => lambda { |shipment| shipment.base.account }
      attribute :payor_country,               :string,      :default => 'US'
      
      # delivery options
      attribute :ship_time,                   :datetime,    :default => lambda { |shipment| Time.now }
      attribute :service_type,                :string,      :default => "FEDEX_GROUND"
      attribute :dropoff_type,                :string,      :default => "REGULAR_PICKUP"
      attribute :special_services_requested,  :array,       :default => []
      attribute :signature,                   :string
      attribute :dangerous_goods,             :boolean,     :default => false
      attribute :dangerous_goods_accessibility, :string,    :default => 'INACCESSIBLE'
      attribute :dangerous_goods_cargo_aircraft_only, :boolean, :default => false
      attribute :dangerous_goods_options,     :string,      :default => 'HAZARDOUS_MATERIALS'
      attribute :hazardous_commodities,       :array,       :default => []
      
      # misc options
      attribute :just_validate,               :boolean,     :default => false
      attribute :rate_request_types,          :array,       :default => ["ACCOUNT"]
      attribute :customer_transaction_id,     :string,      :default => 'Test_transaction_id'
      
      # commercial invoice
      attribute :terms_of_sale,               :string,      :default => "FOB_OR_FCA"
      
      # customs options
      attribute :document_content,            :string,      :default => "NON_DOCUMENTS"
      attribute :item_amount,                 :string,      :default => "100.00" # Remove this default
      attribute :number_of_pieces,            :string,      :default => "1"
      attribute :description,                 :string,      :default => "Book"
      attribute :country_of_manufacture,      :string,      :default => "US"
      attribute :quantity,                    :string,      :default => "1"
      attribute :quantity_units,              :string,      :default => "EA"
      attribute :export_compliance_statement, :string,      :default => "NO EEI 30.36"
      
      # smart post attributes
      attribute :indicia,                     :string,      :default => 'PARCEL_SELECT'
      attribute :ancillary_endorsement,       :string,      :default => 'CARRIER_LEAVE_IF_NO_RESPONSE'
      attribute :hub_id,                      :string,      :default => '5531'
      
      # logging
      attribute :log,                         :string
      
      private
        def target
          @target ||= parse_response(request(build_request))
        end
        
        # Just building some XML to send off to FedEx using our various options
        def build_request
          currency = 'USD'
          
          b = builder
          xml = b.tag!(just_validate ? "ValidateShipmentRequest" : "ProcessShipmentRequest", :xmlns => "http://fedex.com/ws/ship/v#{VERSION[:major]}") do
            build_authentication(b)
            build_version(b, "ship", VERSION[:major], VERSION[:intermediate], VERSION[:minor])
            
            b.RequestedShipment do
              b.ShipTimestamp ship_time.xmlschema if ship_time
              b.DropoffType dropoff_type if dropoff_type
              b.ServiceType service_type if service_type
              b.PackagingType packaging_type if packaging_type
              # b.PreferredCurrency currency if currency
              build_insured_value(b)
              
              b.Shipper do
                build_contact(b, :shipper)
                build_address(b, :shipper)
              end
              
              b.Recipient do
                build_contact(b, :recipient)
                build_address(b, :recipient)
              end
              
              b.ShippingChargesPayment do
                b.PaymentType payment_type if payment_type
                b.Payor do
                  b.AccountNumber payor_account_number if payor_account_number
                  b.CountryCode payor_country if payor_country
                end
              end
              
              if service_type == 'SMART_POST'
                b.SmartPostDetail do
                  b.Indicia indicia
                  b.AncillaryEndorsement ancillary_endorsement
                  b.HubId hub_id
                end
              end

              # # This is valid but I'm removing it as it's not needed for my project.
              if FedEx::Enumerations::INTERNATIONAL_SERVICE_TYPES.include?(service_type)
                b.CustomsClearanceDetail do
                  b.DutiesPayment do
                    b.PaymentType payment_type if payment_type
                    b.Payor do
                      b.AccountNumber payor_account_number if payor_account_number
                      b.CountryCode payor_country if payor_country
                    end
                  end
                  b.DocumentContent document_content if document_content
                  b.CustomsValue do
                    b.Currency currency if currency
                    b.Amount item_amount if item_amount
                  end
                  # b.CommercialInvoice do
                  #   b.TermsOfSale terms_of_sale if terms_of_sale
                  # end
                  b.Commodities do
                    b.NumberOfPieces number_of_pieces if number_of_pieces
                    b.Description description if description
                    b.CountryOfManufacture country_of_manufacture if country_of_manufacture
                    b.Weight do
                      b.Units package_weight_units if package_weight_units
                      b.Value package_weight if package_weight
                    end
                    b.Quantity quantity if quantity
                    b.QuantityUnits quantity_units if quantity_units
                    b.UnitPrice do
                      b.Currency currency if currency
                      b.Amount item_amount if item_amount
                    end
                    b.CustomsValue do
                      b.Currency currency if currency
                      b.Amount item_amount if item_amount
                    end
                  end
                
                  b.ExportDetail do
                    b.ExportComplianceStatement export_compliance_statement if export_compliance_statement
                  end
                end
              end
              
              b.LabelSpecification do
                b.LabelFormatType label_format if label_format
                b.ImageType label_file_type if label_file_type
                b.LabelStockType label_stock_type if label_stock_type
              end
                     
              b.RateRequestTypes rate_request_types.join(",")
              build_package(b)
            end
          end
        end
        
        # Making sense of the reponse and grabbing the information we need.
        def parse_response(response)      
          details = response[:completed_shipment_detail]
          shipment = Shipment.new
          
          # In case a label is returned without rates
          if details.has_key?(:shipment_rating)
            rate_details = details[:shipment_rating][:shipment_rate_details]
            rate_details = rate_details.kind_of?(Array) ? rate_details.first : rate_details
          
            rate = rate_details[:total_net_charge] || rate_details.first[:total_net_charge]
            shipment.rate = BigDecimal.new(rate[:amount])
            shipment.currency = rate[:currency]
          end
          
          package_details = details[:completed_package_details]
          shipment.delivery_date = Date.parse(details[:routing_detail][:delivery_date]) if details[:routing_detail][:delivery_date]
          shipment.tracking_numbers = {}
          
          if package_details[:tracking_ids].kind_of?(Array)
            shipment.tracking_number = package_details[:tracking_ids].first[:tracking_number]
            package_details[:tracking_ids].each do |trk|
              shipment.tracking_numbers[trk[:tracking_id_type]] = trk[:tracking_number]
            end
          else
            shipment.tracking_number = package_details[:tracking_ids][:tracking_number]
          end
          shipment.label = package_details[:label][:parts][:image] && Base64.decode64(package_details[:label][:parts][:image])
          
          unless package_details[:barcodes][:binary_barcodes].nil?
            shipment.barcode = package_details[:barcodes][:binary_barcodes][:value] && Base64.decode64(package_details[:barcodes][:binary_barcodes][:value])
          end
          
          shipment
        end
    end
  end
end