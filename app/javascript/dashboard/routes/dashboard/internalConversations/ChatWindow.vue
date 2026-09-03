<script setup>
import { ref, computed, watch, onMounted, nextTick } from 'vue';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const store = useStore();
const currentUserId = useMapGetter('getCurrentUserID');
const messagesUiFlags = useMapGetter('internalConversations/getMessagesUIFlags');

const messages = computed(() =>
  store.getters['internalConversations/getMessagesByConversationId'](
    props.conversation.id
  )
);

const messageContent = ref('');
const messagesContainer = ref(null);

const scrollToBottom = () => {
  nextTick(() => {
    const el = messagesContainer.value;
    if (el) el.scrollTop = el.scrollHeight;
  });
};

const fetchMessages = async () => {
  await store.dispatch('internalConversations/fetchMessages', props.conversation.id);
  scrollToBottom();
};

const sendMessage = async () => {
  const content = messageContent.value.trim();
  if (!content || messagesUiFlags.value.isSending) return;

  messageContent.value = '';
  await store.dispatch('internalConversations/sendMessage', {
    conversationId: props.conversation.id,
    content,
  });
  scrollToBottom();
};

const handleKeydown = event => {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    sendMessage();
  }
};

const isMine = message => message.sender?.id === currentUserId.value;

const formatTime = timestamp => {
  if (!timestamp) return '';
  return new Date(timestamp).toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
  });
};

onMounted(fetchMessages);

watch(
  () => props.conversation.id,
  () => fetchMessages()
);
</script>

<template>
  <div class="flex flex-col flex-1 h-full min-w-0">
    <header class="flex items-center px-4 h-12 border-b border-n-weak flex-shrink-0">
      <h3 class="m-0 text-sm font-medium text-n-slate-12">
        {{ conversation.display_name }}
      </h3>
    </header>

    <div
      ref="messagesContainer"
      class="overflow-y-auto flex-1 p-4"
    >
      <p
        v-if="messagesUiFlags.isFetching && !messages.length"
        class="text-sm text-center text-n-slate-11"
      >
        {{ $t('INTERNAL_CHAT.LOADING_MESSAGES') }}
      </p>
      <p
        v-else-if="!messages.length"
        class="text-sm text-center text-n-slate-11"
      >
        {{ $t('INTERNAL_CHAT.NO_MESSAGES') }}
      </p>
      <div
        v-for="message in messages"
        :key="message.id"
        class="flex mb-3"
        :class="isMine(message) ? 'justify-end' : 'justify-start'"
      >
        <div
          class="px-3 py-2 max-w-[70%] rounded-lg"
          :class="
            isMine(message)
              ? 'bg-n-brand text-white rounded-br-none'
              : 'bg-n-alpha-2 text-n-slate-12 rounded-bl-none'
          "
        >
          <p class="m-0 text-sm whitespace-pre-wrap break-words">
            {{ message.content }}
          </p>
          <span
            class="block mt-1 text-[11px] opacity-70"
          >
            {{ formatTime(message.created_at) }}
          </span>
        </div>
      </div>
    </div>

    <footer class="flex gap-2 items-end p-3 border-t border-n-weak flex-shrink-0">
      <textarea
        v-model="messageContent"
        rows="1"
        class="flex-1 px-3 py-2 text-sm rounded-lg border resize-none border-n-weak bg-n-background focus:outline-none focus:ring-1 focus:ring-n-brand"
        :placeholder="$t('INTERNAL_CHAT.MESSAGE_PLACEHOLDER')"
        @keydown="handleKeydown"
      />
      <button
        class="flex justify-center items-center rounded-lg size-9 bg-n-brand text-white disabled:opacity-50"
        :disabled="!messageContent.trim() || messagesUiFlags.isSending"
        @click="sendMessage"
      >
        <span class="i-lucide-send size-4" />
      </button>
    </footer>
  </div>
</template>