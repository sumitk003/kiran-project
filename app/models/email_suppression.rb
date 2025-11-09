# frozen_string_literal: true

class EmailSuppression < ApplicationRecord
  belongs_to :contact, optional: true
  belongs_to :agent, optional: true
  belongs_to :account, optional: true

  validates :email, presence: true
  validates :unsubscribed_at, presence: true
  validates :email, uniqueness: { scope: :account_id, message: "is already unsubscribed" }

  scope :for_email, ->(email) { where(email: email) }
  scope :for_account, ->(account_id) { where(account_id: account_id) }
  scope :active, -> { where.not(unsubscribed_at: nil) }

  def self.suppressed?(email, account_id = nil)
    if account_id
      where(email: email, account_id: account_id).exists?
    else
      where(email: email).exists?
    end
  end
end

