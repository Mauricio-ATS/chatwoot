class Api::V1::Accounts::InternalMessagesController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation

  def index
    @messages = @conversation.internal_messages.order(created_at: :asc)
  end

    def create
    @message = @conversation.internal_messages.new(
      account: Current.account,
      user: Current.user,
      content: params[:content],
      message_type: :text
    )

    attachment_params.each do |signed_id|
      blob = ActiveStorage::Blob.find_signed!(signed_id)

      @message.internal_message_attachments.build(
        account: Current.account,
        file: blob
      )
    end

    @message.save!

    render :show
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    render json: { error: 'Anexo inválido' }, status: :unprocessable_entity
  end

  private

  def fetch_conversation
    @conversation = Current.user.internal_conversations.find(params[:internal_conversation_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Conversa não encontrada' }, status: :not_found
  end
    def attachment_params
    Array(params[:attachments]).reject(&:blank?)
  end
end