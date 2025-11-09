# frozen_string_literal: true

require 'digest'

class UnsubscribesController < ApplicationController
  skip_before_action :authenticate_agent!
  skip_before_action :verify_authenticity_token, only: [:create]

  def show
    @token = params[:token]
    @email = params[:email]
    @account_id = params[:account_id]
    
    if @token && @email && @account_id && verify_token(@token, @email, @account_id)
      @contact = Contact.find_by(email: @email, account_id: @account_id) if @email && @account_id
      @account = Account.find(@account_id) if @account_id
    else
      redirect_to root_path, alert: 'Invalid unsubscribe link.'
    end
  end

  def create
    email = params[:email]
    account_id = params[:account_id]
    token = params[:token]

    unless verify_token(token, email, account_id)
      redirect_to root_path, alert: 'Invalid unsubscribe link.'
      return
    end

    contact = Contact.find_by(email: email, account_id: account_id) if email && account_id
    account = Account.find(account_id) if account_id

    suppression = EmailSuppression.find_or_initialize_by(
      email: email,
      account_id: account_id
    )

    suppression.assign_attributes(
      contact_id: contact&.id,
      agent_id: contact&.agent_id,
      unsubscribed_at: Time.current
    )

    if suppression.save
      redirect_to unsubscribe_success_path, notice: 'You have been successfully unsubscribed from future emails.'
    else
      redirect_to root_path, alert: 'Failed to unsubscribe. Please try again.'
    end
  end

  def success
    # Success page
  end

  private

  def verify_token(token, email, account_id)
    return false unless token && email && account_id
    
    expected_token = generate_token(email, account_id)
    ActiveSupport::SecurityUtils.secure_compare(token, expected_token)
  end

  def generate_token(email, account_id)
    Digest::SHA256.hexdigest("#{email}#{account_id}#{Rails.application.credentials.secret_key_base}")
  end
end

