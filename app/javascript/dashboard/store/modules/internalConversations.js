import types from '../mutation-types';
import InternalConversationsAPI from '../../api/internalConversations';

const state = {
  records: [],
  messagesById: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isError: false,
  },
  messagesUiFlags: {
    isFetching: false,
    isSending: false,
  },
};

export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getMessagesUIFlags($state) {
    return $state.messagesUiFlags;
  },
  getInternalConversations($state) {
    return $state.records;
  },
  getInternalConversationById: $state => id => {
    return $state.records.find(record => record.id === Number(id));
  },
  getSelfChat: $state => {
    return $state.records.find(record => record.self_chat);
  },
  getMessagesByConversationId: $state => conversationId => {
    return $state.messagesById[Number(conversationId)] || [];
  },
};

export const actions = {
    handleRealtimeMessage: ({ commit }, data) => {
    const message = data.internal_message;

    if (!message) {
      return;
    }

    commit(types.ADD_INTERNAL_MESSAGE, {
      conversationId: message.internal_conversation_id,
      message,
    });
  },
  fetchAll: async ({ commit }) => {
    commit(types.SET_INTERNAL_CONVERSATIONS_UI_FLAG, { isFetching: true });
    try {
      const response = await InternalConversationsAPI.get();
      commit(types.SET_INTERNAL_CONVERSATIONS, response.data.payload);
      commit(types.SET_INTERNAL_CONVERSATIONS_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.SET_INTERNAL_CONVERSATIONS_UI_FLAG, {
        isFetching: false,
        isError: true,
      });
      throw new Error(error);
    }
  },

  openSelfChat: async ({ commit }) => {
    commit(types.SET_INTERNAL_CONVERSATIONS_UI_FLAG, { isCreating: true });
    try {
      const response = await InternalConversationsAPI.getSelfChat();
      commit(types.SET_INTERNAL_CONVERSATIONS, [response.data]);
      commit(types.SET_INTERNAL_CONVERSATIONS_UI_FLAG, { isCreating: false });
      return response.data;
    } catch (error) {
      commit(types.SET_INTERNAL_CONVERSATIONS_UI_FLAG, {
        isCreating: false,
        isError: true,
      });
      throw new Error(error);
    }
  },

  openDirect: async ({ commit }, userId) => {
    commit(types.SET_INTERNAL_CONVERSATIONS_UI_FLAG, { isCreating: true });
    try {
      const response = await InternalConversationsAPI.createDirect(userId);
      commit(types.SET_INTERNAL_CONVERSATIONS, [response.data]);
      commit(types.SET_INTERNAL_CONVERSATIONS_UI_FLAG, { isCreating: false });
      return response.data;
    } catch (error) {
      commit(types.SET_INTERNAL_CONVERSATIONS_UI_FLAG, {
        isCreating: false,
        isError: true,
      });
      throw new Error(error);
    }
  },

  markAsRead: async ({ commit }, conversationId) => {
    try {
      await InternalConversationsAPI.markAsRead(conversationId);
      commit(types.SET_INTERNAL_CONVERSATIONS, [
        { id: Number(conversationId), unread_count: 0 },
      ]);
    } catch (error) {
      // silencioso: não bloqueia UX se marcar como lido falhar
    }
  },

  fetchMessages: async ({ commit }, conversationId) => {
    commit(types.SET_INTERNAL_MESSAGES_UI_FLAG, { isFetching: true });
    try {
      const response = await InternalConversationsAPI.getMessages(conversationId);
      commit(types.SET_INTERNAL_MESSAGES, {
        conversationId,
        messages: response.data.payload,
      });
      commit(types.SET_INTERNAL_MESSAGES_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.SET_INTERNAL_MESSAGES_UI_FLAG, { isFetching: false });
      throw new Error(error);
    }
  },

  sendMessage: async ({ commit }, { conversationId, content }) => {
    commit(types.SET_INTERNAL_MESSAGES_UI_FLAG, { isSending: true });
    try {
      const response = await InternalConversationsAPI.createMessage(
        conversationId,
        content
      );
      commit(types.ADD_INTERNAL_MESSAGE, {
        conversationId,
        message: response.data,
      });
      commit(types.SET_INTERNAL_MESSAGES_UI_FLAG, { isSending: false });
    } catch (error) {
      commit(types.SET_INTERNAL_MESSAGES_UI_FLAG, { isSending: false });
      throw new Error(error);
    }
  },
};

export const mutations = {
  [types.SET_INTERNAL_CONVERSATIONS_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  [types.SET_INTERNAL_MESSAGES_UI_FLAG]($state, data) {
    $state.messagesUiFlags = { ...$state.messagesUiFlags, ...data };
  },
  [types.SET_INTERNAL_CONVERSATIONS]($state, conversations) {
    conversations.forEach(conversation => {
      const index = $state.records.findIndex(
        record => record.id === conversation.id
      );
      if (index !== -1) {
        $state.records[index] = { ...$state.records[index], ...conversation };
      } else {
        $state.records.push(conversation);
      }
    });
  },
  [types.SET_INTERNAL_MESSAGES]($state, { conversationId, messages }) {
    $state.messagesById = {
      ...$state.messagesById,
      [Number(conversationId)]: messages,
    };
  },
  [types.ADD_INTERNAL_MESSAGE]($state, { conversationId, message }) {
    const key = Number(conversationId);
    const existing = $state.messagesById[key] || [];

    if (existing.some(item => item.id === message.id)) {
      return;
    }

    $state.messagesById = {
      ...$state.messagesById,
      [key]: [...existing, message],
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};