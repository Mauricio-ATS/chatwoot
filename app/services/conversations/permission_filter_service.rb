class Conversations::PermissionFilterService
  attr_reader :conversations, :user, :account

  def initialize(conversations, user, account, plan_hint_selective_filter: false)
    @conversations = conversations
    @user = user
    @account = account
    @plan_hint_selective_filter = plan_hint_selective_filter
  end

  def perform
    return conversations if user_role == 'administrator'

    accessible_conversations
  end

  private

  def accessible_conversations
    result = @conversations.where(
      inbox: user.inboxes.where(account_id: account.id)
    )

    return result unless restricted_conversation_visibility?

    result.where(
      'conversations.assignee_id = :user_id OR conversations.assignee_id IS NULL',
      user_id: user.id
    )
  end

  # Same rows as accessible_conversations. `inbox_id + 0` keeps the planner from
  # driving the query through an inbox scan, which it grossly misestimates when a
  # highly selective filter (e.g. labels) is present on large accounts (CW-7787).
  def hinted_accessible_conversations
    result = @conversations.where(
      '(conversations.inbox_id + 0) IN (
        SELECT inbox_members.inbox_id
        FROM inbox_members
        INNER JOIN inboxes ON inboxes.id = inbox_members.inbox_id
        WHERE inbox_members.user_id = :user_id
        AND inboxes.account_id = :account_id
      )',
      user_id: user.id,
      account_id: account.id
    )

    return result unless restricted_conversation_visibility?

    result.where(
      'conversations.assignee_id = :user_id OR conversations.assignee_id IS NULL',
      user_id: user.id
    )
  end

  def restricted_conversation_visibility?
    account.agents_can_only_see_assigned_conversations?
  end

  def account_user
    AccountUser.find_by(account_id: account.id, user_id: user.id)
  end

  def user_role
    account_user&.role
  end
end

Conversations::PermissionFilterService.prepend_mod_with('Conversations::PermissionFilterService')
