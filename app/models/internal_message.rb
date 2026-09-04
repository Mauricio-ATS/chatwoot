# == Schema Information
#
# Table name: internal_messages
#
#  id                       :bigint           not null, primary key
#  content                  :text
#  message_type             :integer          default("text"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#  internal_conversation_id :bigint           not null
#  user_id                  :bigint           not null
#
# Indexes
#
#  index_internal_messages_on_account_id                (account_id)
#  index_internal_messages_on_internal_conversation_id  (internal_conversation_id)
#  index_internal_messages_on_user_id                   (user_id)
#
class InternalMessage < ApplicationRecord
  belongs_to :internal_conversation
  belongs_to :account
  belongs_to :user

  has_many :internal_message_attachments, dependent: :destroy, autosave: true

  enum message_type: { text: 0, system: 1 }

  validates :content, presence: true, if: -> { text? && internal_message_attachments.blank? }

  after_create_commit :dispatch_created_event
  after_create_commit :touch_conversation_activity
    private

  def dispatch_created_event
      Rails.configuration.dispatcher.dispatch(
        INTERNAL_MESSAGE_CREATED,
        Time.zone.now,
        internal_message: self,
        performed_by: Current.executed_by
      )
  end

  def touch_conversation_activity
    internal_conversation.touch_last_activity!
  end
end
