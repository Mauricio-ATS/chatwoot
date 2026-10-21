/* global axios */
import ApiClient from './ApiClient';

class InternalConversationsAPI extends ApiClient {
  constructor() {
    super('internal_conversations', { accountScoped: true });
  }

  getSelfChat() {
    return axios.post(this.url, { self_chat: true });
  }

  createDirect(userId) {
    return axios.post(this.url, { user_id: userId });
  }

  markAsRead(conversationId) {
    return axios.post(`${this.url}/${conversationId}/mark_as_read`);
  }

  getMessages(conversationId) {
    return axios.get(`${this.url}/${conversationId}/internal_messages`);
  }

  createMessage(conversationId, { content, attachments = [] }) {
    return axios.post(`${this.url}/${conversationId}/internal_messages`, {
      content,
      attachments,
    });
  }
}

export default new InternalConversationsAPI();
