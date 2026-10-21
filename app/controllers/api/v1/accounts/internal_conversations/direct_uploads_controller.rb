class Api::V1::Accounts::InternalConversations::DirectUploadsController < ActiveStorage::DirectUploadsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  include RequestExceptionHandler
  include AccessTokenAuthHelper
  include EnsureCurrentAccountHelper

  skip_before_action :verify_authenticity_token, if: :authenticate_by_access_token?

  around_action :handle_with_exception
  before_action :authenticate_access_token!, if: :authenticate_by_access_token?
  before_action :authenticate_user!, unless: :authenticate_by_access_token?
  before_action :current_account
  before_action :conversation

  def create
    return if @conversation.nil? || @current_account.nil?

    super
  end

  private

  def authenticate_by_access_token?
    request.headers[:api_access_token].present? ||
      request.headers[:HTTP_API_ACCESS_TOKEN].present?
  end

  def conversation
    @conversation ||= Current.account.internal_conversations.find(params[:id])
  end
end