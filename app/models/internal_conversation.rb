# == Schema Information
#
# Table name: internal_conversations
#
#  id               :bigint           not null, primary key
#  last_activity_at :datetime
#  self_chat        :boolean          default(FALSE), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  created_by_id    :bigint           not null
#
# Indexes
#
#  index_internal_conversations_on_account_id     (account_id)
#  index_internal_conversations_on_created_by_id  (created_by_id)
#
class InternalConversation < ApplicationRecord
  belongs_to :account
  belongs_to :created_by, class_name: 'User'

  has_many :internal_conversation_participants, dependent: :destroy
  has_many :participants, through: :internal_conversation_participants, source: :user
  has_many :internal_messages, dependent: :destroy

  validates :account_id, presence: true
  validates :created_by_id, presence: true
  scope :ordered_by_activity, -> { order(last_activity_at: :desc) }

  def other_participant(current_user)
    return nil if self_chat?
        return nil if participants.count != 2

        participants.where.not(id: current_user.id).first
        end

        def display_name(current_user)
        return I18n.t('internal_chat.self_notes', default: 'Notas próprias') if self_chat?

        other = other_participant(current_user)
        other&.name || other&.email
    end
  def self.find_or_create_self_chat(user:, account:)
    conversation = joins(:internal_conversation_participants)
                   .where(account_id: account.id, self_chat: true, created_by_id: user.id)
                   .first

    return conversation if conversation

    transaction do
      conversation = create!(account: account, created_by: user, self_chat: true)
      conversation.internal_conversation_participants.create!(user: user, account: account)
    end

    conversation
  end

  # Retorna (ou cria) a conversa 1:1 entre dois usuários distintos
  def self.find_or_create_direct(user_a:, user_b:, account:)
    raise ArgumentError, 'use find_or_create_self_chat para o mesmo usuário' if user_a.id == user_b.id

    existing = where(account_id: account.id, self_chat: false)
               .joins(:internal_conversation_participants)
               .where(internal_conversation_participants: { user_id: [user_a.id, user_b.id] })
               .group('internal_conversations.id')
               .having('COUNT(DISTINCT internal_conversation_participants.user_id) = 2')
               .first

    return existing if existing

    transaction do
      conversation = create!(account: account, created_by: user_a, self_chat: false)
      conversation.internal_conversation_participants.create!(user: user_a, account: account)
      conversation.internal_conversation_participants.create!(user: user_b, account: account)
      conversation
    end
  end

  def touch_last_activity!
    update_column(:last_activity_at, Time.current)
  end
end
