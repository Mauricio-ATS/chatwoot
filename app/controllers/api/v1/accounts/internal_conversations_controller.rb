class Api::V1::Accounts::InternalConversationsController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation, only: [:show, :mark_as_read]

  def index
    @conversations = Current.user.internal_conversations
                             .where(account_id: Current.account.id)
                             .ordered_by_activity
  end

  def show; end

  def create
    if params[:self_chat].present?
      @conversation = InternalConversation.find_or_create_self_chat(
        user: Current.user,
        account: Current.account
      )
    else
      other_user = Current.account.users.find(params[:user_id])
      @conversation = InternalConversation.find_or_create_direct(
        user_a: Current.user,
        user_b: other_user,
        account: Current.account
      )
    end

    render :show
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Usuário não encontrado nesta conta' }, status: :not_found
  end

  def mark_as_read
    participant = @conversation.internal_conversation_participants.find_by!(user: Current.user)
    participant.mark_as_read!
    head :ok
  end

  private

  def fetch_conversation
    @conversation = Current.user.internal_conversations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Conversa não encontrada' }, status: :not_found
  end
end