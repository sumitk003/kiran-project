module Contacts
  class ContactSearchForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :classifications, default: []

    def self.model_name
      ActiveModel::Name.new(self, nil, 'ContactSearchForm')
    end

    def available_classifications
      [
        'Agent',
        'Buyer',
        'Property manager',
        'Vendor',
        'Prospective tenant',
        'Landlord',
        'Tenant',
        'Owner',
        'Tenant representative'
      ]
    end
  end
end
