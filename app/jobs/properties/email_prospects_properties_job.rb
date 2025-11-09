# frozen_string_literal: true

module Properties
  class EmailProspectsPropertiesJob < ApplicationJob
    def perform(agent_id, contact_id, property_ids, body, attachments = nil)
      agent        = find_agent(agent_id)
      contact      = find_contact(contact_id)
      
      # Check if email is suppressed
      if EmailSuppression.suppressed?(contact.email, agent.account.id)
        Rails.logger.info("[#{self.class}] Skipping email to Contact (id: #{contact_id}) - email is suppressed")
        return
      end
      
      to = contact.email
      to = 'grant.barry@free.fr' unless Rails.env.production?
      access_token = agent.microsoft_graph_token.access_token if agent.microsoft_graph_token?
      subject = "#{agent.account.company_name} listings"

      # Use LetterOpenerProvider in development, MicrosoftGraphProvider in production
      email_service_class = Rails.env.development? ? 
        AppServices::Email::LetterOpenerProvider : 
        AppServices::Email::MicrosoftGraphProvider

      email_service = email_service_class.new({
                     access_token: access_token,
                     to: to,
                     subject: subject,
                     body: body,
                     attachments: attachments,
                     from: agent.email || 'noreply@example.com'
                   })

      response = email_service.send_message
      if response.success?
        save_prospect_notification_emails(contact_id, property_ids)
        Rails.logger.info("[#{self.class}] Sent email to Contact (id: #{contact_id}) with properties (#{property_ids.join(', ')})")
      else
        Rails.logger.error("[#{self.class}] ERROR sending email to Contact (id: #{contact_id}) with properties (#{property_ids.join(', ')})")
      end
    end

    private

    def save_prospect_notification_emails(contact_id, property_ids)
      property_ids.each do |property_id|
        ProspectNotificationEmail.find_or_create_by!(contact_id: contact_id, property_id: property_id) do |pne|
          pne.emailed_at = Time.now
        end
      end
    end

    def find_agent(agent_id)
      Agent.find(agent_id)
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error("[#{self.class}] ERROR loading agent #{agent_id}")
      Rails.logger.info(e.message)
    end

    def find_contact(contact_id)
      Contact.find(contact_id)
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error("[#{self.class}] ERROR loading contact #{contact_id}")
      Rails.logger.info(e.message)
    end
  end
end
