# frozen_string_literal: true

module Contacts
  class ContactSearchFormsController < ApplicationController
    include Pagy::Backend

    before_action :authenticate_agent!
    before_action :set_nav_menu

    def new
      @contact_search_form = Contacts::ContactSearchForm.new
    end

    def index
      @contact_search_form = Contacts::ContactSearchForm.new(contact_search_form_params)
      debugger
      @pagy, @contacts = pagy(filtered_contacts)
    end

    private

    def filtered_contacts
      debugger
      contacts = current_agent.contacts.includes(:agent, :classifications)

      contacts = apply_classification_filter(contacts) if selected_classifications.present?
      contacts = apply_filter_param(contacts) if params[:filter].present?

      debugger
      


      contacts = case params[:filter]
                when 'businesses'
                  contacts.order(Arel.sql("COALESCE(business_name, '') ASC"))
                when 'individuals'
                  contacts.order(Arel.sql("COALESCE(first_name, '') ASC"))
                else
                  contacts.order(Arel.sql("COALESCE(first_name, business_name, '') ASC"))
                end

      contacts
    end

    def apply_filter_param(contacts)
      case params[:filter]
      when 'individuals'
        contacts.where(type: 'Individual')
      when 'businesses'
        contacts.where(type: 'Business')
      when '#'
        contacts.where("last_name ~ '^[0-9]' OR business_name ~ '^[0-9]'")
      else
        contacts.where('last_name ILIKE :f OR business_name ILIKE :f', f: "#{params[:filter]}%")
      end
    end

    def apply_classification_filter(contacts)
      normalized = normalize_classifications(selected_classifications)

      contact_ids = Classification.where(classifiable_type: 'Contact').where('LOWER(name) IN (?)', normalized).pluck(:classifiable_id).uniq
    

      contacts.where(id: contact_ids)
    end

    def selected_classifications
      contact_search_form_params[:classifications].presence || []
    end

    def contact_search_form_params
      params.fetch(:contact_search_form, {}).permit(classifications: [])
    end

    def normalize_classifications(names)
      names.map(&:to_s).map(&:strip).map(&:downcase).uniq
    end

    def set_nav_menu
      set_nav_menu_option(:contacts)
    end
  end
end
