module Conversations
  class ForwardMessageService
    def initialize(account:, original_message:, target_contact:, user:)
      @account = account
      @original_message = original_message
      @target_contact = target_contact
      @user = user
    end

    def perform
      target_conversation = find_or_create_conversation
      create_forwarded_message(target_conversation)
    end

    private

    def find_or_create_conversation
      conversation = @account.conversations.where(contact_id: @target_contact.id).last
      return conversation if conversation.present?

      contact_inbox = @target_contact.contact_inboxes.first
      inbox = contact_inbox&.inbox || @account.inboxes.first

      contact_inbox ||= ::ContactInbox.create!(
        contact_id: @target_contact.id,
        inbox_id: inbox.id,
        source_id: @target_contact.identifier || SecureRandom.uuid
      )

      ::Conversation.create!(
        account_id: @account.id,
        inbox_id: inbox.id,
        contact_id: @target_contact.id,
        contact_inbox_id: contact_inbox.id,
        status: :open
      )
    end

    def create_forwarded_message(conversation)
    sender_name = @original_message.sender&.name || 'Contato'

    forwarded_content = <<~CONTENT
      *Mensagem encaminhada de: #{sender_name}*

      #{@original_message.content}
    CONTENT

    params = {
      content: forwarded_content,
      message_type: :outgoing,
      private: false,
      content_attributes: {
        is_forwarded: true,
        original_message_id: @original_message.id
      }
    }

    builder = Messages::MessageBuilder.new(@user, conversation, params)
    new_message = builder.perform

    if new_message.present? && @user.present?
      new_message.update!(sender: @user)
    end

    duplicate_attachments(new_message) if new_message.present? && @original_message.attachments.present?

    new_message
  end

    def duplicate_attachments(new_message)
      @original_message.attachments.each do |attachment|
        next unless attachment.file.attached?

        new_attachment = new_message.attachments.build(
          account_id: @account.id,
          file_type: attachment.file_type
        )
        new_attachment.file.attach(attachment.file.blob)
        new_attachment.save!
      end
    end
  end
end