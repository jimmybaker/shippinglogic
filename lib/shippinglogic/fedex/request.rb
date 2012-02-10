require "builder"
require "logger"

module Shippinglogic
  class FedEx
    # Methods relating to building and sending a request to FedEx's web services.
    module Request
      private
        # Convenience method for sending requests to FedEx
        def request(body)
          if respond_to?(:log) && log
            logger = Logger.new(log)
            logger.info body
          end
          
          real_class.post(base.url, :body => body)
        end
        
        # Convenience method to create a builder object so that our builder options are consistent across
        # the various services.
        #
        # Ex: if I want to change the indent level to 3 it should change for all requests built.
        def builder
          b = Builder::XmlMarkup.new(:indent => 2)
          b.instruct!
          b
        end
        
        # A convenience method for building the authentication block in your XML request
        def build_authentication(b)
          b.WebAuthenticationDetail do
            # if true # International needs to be passed in
            #   b.CspCredential do
            #     b.Key base.key
            #     b.Password base.password
            #   end
            # end
            b.UserCredential do
              b.Key base.key
              b.Password base.password
            end
          end
          
          b.ClientDetail do
            b.AccountNumber base.account
            b.MeterNumber base.meter
          end
          
          b.TransactionDetail do
            b.CustomerTransactionId customer_transaction_id
          end
        end
        
        # A convenience method for building the version block in your XML request
        def build_version(b, service, major, intermediate, minor)
          b.Version do
            b.ServiceId service
            b.Major major
            b.Intermediate intermediate
            b.Minor minor
          end
        end
        
        # A convenience method for building the contact block in your XML request
        def build_contact(b, type)
          b.Contact do
            b.PersonName send("#{type}_name") if send("#{type}_name")
            b.Title send("#{type}_title") if send("#{type}_title")
            b.CompanyName send("#{type}_company_name") if send("#{type}_company_name")
            b.PhoneNumber send("#{type}_phone_number") if send("#{type}_phone_number")
            b.EMailAddress send("#{type}_email") if send("#{type}_email")
          end
        end
        
        # A convenience method for building the address block in your XML request
        def build_address(b, type)
          b.Address do
            send("#{type}_streets").each do |street|
              b.StreetLines street
            end
            b.City send("#{type}_city") if send("#{type}_city")
            b.StateOrProvinceCode state_code(send("#{type}_state")) if send("#{type}_state")
            b.PostalCode send("#{type}_postal_code") if send("#{type}_postal_code")
            b.CountryCode country_code(send("#{type}_country")) if send("#{type}_country")
            b.Residential send("#{type}_residential")
          end
        end
        
        def build_insured_value(b)
          if insured_value
            b.TotalInsuredValue do
              b.Currency currency_type
              b.Amount insured_value
            end
          end
        end
        
        # A convenience method for building the package block in your XML request
        def build_package(b)
          b.PackageCount package_count
          b.PackageDetail package_detail
          
          b.RequestedPackageLineItems do
            b.SequenceNumber 1
            
            b.Weight do
              b.Units package_weight_units
              b.Value package_weight
            end
            
            if custom_packaging?
              b.Dimensions do
                b.Length package_length
                b.Width package_width
                b.Height package_height
                b.Units package_dimension_units
              end
            end
            
            b.CustomerReferences do
              b.CustomerReferenceType 'CUSTOMER_REFERENCE'
              b.Value customer_reference_number
            end
            
            b.CustomerReferences do
              b.CustomerReferenceType 'INVOICE_NUMBER'
              b.Value invoice_number
            end
            
            b.CustomerReferences do
              b.CustomerReferenceType 'P_O_NUMBER'
              b.Value po_number
            end
        
            # 
            # b.SpecialServicesRequested do
            #   b.SpecialServiceTypes 'DANGEROUS_GOODS'
            #   b.DangerousGoodsDetail do
            #     b.Accessibility 'ACCESSIBLE'
            #   end
            # end
            
            if respond_to?(:dangerous_goods) && dangerous_goods
              self.special_services_requested << "DANGEROUS_GOODS"
            end
            
            if respond_to?(:signature) && signature
              self.special_services_requested << "SIGNATURE_OPTION"
            end
            
            if (respond_to?(:special_services_requested) && special_services_requested.any?)
              b.SpecialServicesRequested do
                if special_services_requested.any?
                  b.SpecialServiceTypes special_services_requested.join(",")
                end
              
                if signature
                  b.SignatureOptionDetail do
                    b.OptionType signature
                  end
                end
                
                if dangerous_goods
                  b.DangerousGoodsDetail do
                    b.Accessibility 'ACCESSIBLE'
                    b.CargoAircraftOnly false
                    b.Options 'HAZARDOUS_MATERIALS'
                    hazardous_commodities.each do |commodity|
                      b.HazardousCommodities do
                        b.Description do
                           b.Id commodity[:id]
                           b.PackingGroup commodity[:packing_group]
                           b.ProperShippingName commodity[:proper_shipping_name]
                           b.TechnicalName commodity[:technical_name]
                           b.HazardClass commodity[:hazard_class]
                           b.SubsidiaryClasses commodity[:subsidiary_classes]
                           b.LabelText commodity[:label_text]
                        end
                        b.Quantity do
                          b.Amount commodity[:amount]
                          b.Units commodity[:units]
                        end
                        b.Options do
                          b.LabelTextOption "APPEND"
                          b.CustomerSuppliedLabelText commodity[:customer_supplied_label_text]
                        end
                      end
                    end
                  end
                end
                
              end
            end
          end
        end
        
        def custom_packaging?
          packaging_type == "YOUR_PACKAGING"
        end
        
        def country_code(value)
          Enumerations::FEDEX_COUNTRY_CODES[value.to_s] || Enumerations::RAILS_COUNTRY_CODES[value.to_s] || value.to_s
        end
        
        def state_code(value)
          Enumerations::STATE_CODES[value.to_s] || value.to_s
        end
    end
  end
end