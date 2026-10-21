<script setup>
import { computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import ConversationList from './ConversationList.vue';
import ChatWindow from './ChatWindow.vue';

const props = defineProps({
  conversationId: {
    type: [String, Number],
    default: null,
  },
});

const store = useStore();

const conversations = useMapGetter('internalConversations/getInternalConversations');
const uiFlags = useMapGetter('internalConversations/getUIFlags');

const activeConversation = computed(() => {
  if (!props.conversationId) return null;
  return conversations.value.find(
    c => c.id === Number(props.conversationId)
  );
});

onMounted(() => {
  store.dispatch('internalConversations/fetchAll');
});

watch(
  () => props.conversationId,
  newId => {
    if (newId) {
      store.dispatch('internalConversations/markAsRead', newId);
    }
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex w-full h-full overflow-hidden">
    <ConversationList
      :conversations="conversations"
      :is-fetching="uiFlags.isFetching"
      :active-conversation-id="conversationId ? Number(conversationId) : null"
    />
    <ChatWindow
      v-if="activeConversation"
      :key="activeConversation.id"
      :conversation="activeConversation"
    />
    <div v-else class="flex flex-col flex-1 justify-center items-center text-n-slate-11">
      <span class="mb-2 i-lucide-messages-square size-10" />
      <p>{{ $t('INTERNAL_CHAT.SELECT_CONVERSATION') }}</p>
    </div>
  </div>
</template>