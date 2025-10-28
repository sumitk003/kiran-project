# frozen_string_literal: true

module Contacts
  class BulkContactEmailsController < ApplicationController
    include ActiveStorage::SetCurrent

    before_action :authenticate_agent!
    before_action :set_contacts

    # GET /bulk_contact_emails/new
    def new
      if @current_agent.sends_email_via_microsoft_graph? &&
        (@current_agent.microsoft_graph_token_missing? || @current_agent.microsoft_graph_token.expired?)
        redirect_to edit_agent_path(@current_agent), alert: 'You are not connected to Microsoft Office online. Please connect to Microsoft Graph to send emails.'
      else
        # Store contact_ids in session for the create action
        session[:bulk_email_contact_ids] = params[:contact_ids] if params[:contact_ids].present?
        
        # If no contact_ids provided, redirect back to contact search
        if params[:contact_ids].blank? && session[:bulk_email_contact_ids].blank?
          redirect_to contact_search_forms_path, alert: 'Please select contacts to send emails to.'
          return
        end
        
        @bulk_contact_email = BulkContactEmail.new(body: default_email_body)
        @properties = current_agent.properties.limit(30).order(created_at: :desc)
        set_tab_option(:contacts)
      end
    end

    # POST /bulk_contact_emails
    def create
      set_tab_option(:contacts)
      
      # Check if contacts are selected
      if @contacts.empty?
        @bulk_contact_email = BulkContactEmail.new(bulk_contact_email_params)
        @bulk_contact_email.errors.add(:contacts, "Please select at least one contact to send emails to.")
        @properties = current_agent.properties.limit(30).order(created_at: :desc)
        
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @bulk_contact_email.errors, status: :unprocessable_entity }
        end
        return
      end
      
      # Check if properties are selected
      @bulk_contact_email = BulkContactEmail.new(bulk_contact_email_params)
      
      if @bulk_contact_email.property_ids.blank?
        @bulk_contact_email.errors.add(:property_ids, "Please select at least one property from the list above to send information about.")
        @properties = current_agent.properties.limit(30).order(created_at: :desc)
        
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @bulk_contact_email.errors, status: :unprocessable_entity }
        end
        return
      end
      
      respond_to do |format|
        if send_bulk_emails
          format.html { redirect_to contact_search_forms_path, notice: 'Bulk contact emails were sent successfully.' }
          format.json { render json: { status: 'success', message: 'Bulk contact emails were sent successfully.' } }
        else
          @properties = current_agent.properties.limit(30).order(created_at: :desc)
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @bulk_contact_email.errors, status: :unprocessable_entity }
        end
      end
    end

    private

    def set_contacts
      # Get contact_ids from params or session
      contact_ids = params[:contact_ids] || session[:bulk_email_contact_ids]
      
      if contact_ids.blank?
        @contacts = []
        return
      end
      
      @contacts = current_agent.contacts.where(id: contact_ids)
      
      # Clear session after use
      session.delete(:bulk_email_contact_ids) if session[:bulk_email_contact_ids]
    end

    def default_email_body
      "Hello,\n\nHere are a few listings that you may be looking for.\nLet me know if you are interested.\n\nKind regards,\n#{@current_agent.name}"
    end

    def send_bulk_emails
      @bulk_contact_email = BulkContactEmail.new(bulk_contact_email_params)
      
      return false unless @bulk_contact_email.valid?
      
      @contacts.each do |contact|
        send_email_to_contact(contact)
      end
      
      true
    rescue => e
      Rails.logger.error "Bulk contact email error: #{e.message}"
      @bulk_contact_email.errors.add(:base, "Failed to send emails: #{e.message}")
      false
    end

    def send_email_to_contact(contact)
      # Create individual matching properties email for each contact
      matching_email = MatchingPropertiesEmail.create!(
        contact: contact,
        agent: @current_agent,
        body: @bulk_contact_email.body,
        attach_brochures: @bulk_contact_email.attach_brochures,
        property_ids: @bulk_contact_email.property_ids
      )

      # Attach files if any
      if @bulk_contact_email.files.present?
        @bulk_contact_email.files.each do |file|
          matching_email.files.attach(file)
        end
      end

      # Send the email using the existing service
      email_service = AppServices::Contacts::MatchingPropertiesEmailer.new(
        matching_properties_email_params(matching_email)
      )
      
      email_service.send_matching_properties_email
    end

    def matching_properties_email_params(matching_email)
      {
        body: @bulk_contact_email.body,
        attach_brochures: @bulk_contact_email.attach_brochures,
        files: @bulk_contact_email.files,
        property_ids: @bulk_contact_email.property_ids,
        agent: @current_agent,
        contact: matching_email.contact
      }
    end

    def bulk_contact_email_params
      permitted_params = params.require(:bulk_contact_email)
                               .permit(:body, :attach_brochures, files: [])
      
      # Get property_ids from top-level params (since checkboxes are outside the form model)
      property_ids = params[:property_ids] || []
      
      permitted_params.merge({ 
        agent: @current_agent, 
        contacts: @contacts,
        property_ids: property_ids
      })
    end
  end
end
