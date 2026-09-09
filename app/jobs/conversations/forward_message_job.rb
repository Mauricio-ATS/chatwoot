module Conversations
  class ForwardMessageJob < ApplicationJob
    queue_as :medium

    def perform(account_id:, original_message_id:, target_contact_id:, user_id:, include_header: true)
      account = Account.find(account_id)
      original_message = Message.find(original_message_id)
      target_contact = Contact.find(target_contact_id)
      user = User.find(user_id)

      Conversations::ForwardMessageService.new(
        account: account,
        original_message: original_message,
        target_contact: target_contact,
        user: user,
        include_header: include_header
      ).perform
    rescue StandardError => e
      Rails.logger.error "[FORWARD JOB ERROR] #{e.message}\n#{e.backtrace.join("\n")}"
      raise e
    end
  end
end