# == Schema Information
#
# Table name: internal_conversation_participants
#
#  id                       :bigint           not null, primary key
#  last_read_at             :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#  internal_conversation_id :bigint           not null
#  user_id                  :bigint           not null
#
# Indexes
#
#  idx_int_conv_participants_conversation               (internal_conversation_id)
#  idx_int_conv_participants_unique                     (internal_conversation_id,user_id) UNIQUE
#  index_internal_conversation_participants_on_user_id  (user_id)
#
class InternalConversationParticipant < ApplicationRecord
  belongs_to :internal_conversation
  belongs_to :user
  belongs_to :account

  validates :user_id, uniqueness: { scope: :internal_conversation_id }
  validate :self_chat_has_single_participant

  def unread_count
    scope = internal_conversation.internal_messages
    scope = scope.where('created_at > ?', last_read_at) if last_read_at.present?
    scope.count
  end

  def mark_as_read!
    update!(last_read_at: Time.current)
  end

  private

  def self_chat_has_single_participant
    return unless internal_conversation&.self_chat?

    existing = internal_conversation.internal_conversation_participants.where.not(id: id).count
    errors.add(:base, 'self chat só pode ter um participante') if existing.positive?
  end
end
