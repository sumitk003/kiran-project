# frozen_string_literal: true

class BulkContactEmail
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :body, :string
  attribute :attach_brochures, :boolean, default: false
  attribute :files, default: []
  attribute :property_ids, default: []
  attribute :agent
  attribute :contacts, default: []

  validates :body, presence: true
  validates :contacts, presence: true

  def self.model_name
    ActiveModel::Name.new(self, nil, 'BulkContactEmail')
  end

  def properties
    return [] if property_ids.blank?
    
    agent.properties.where(id: property_ids)
  end

  def selected_properties
    properties
  end
end
