<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import NewConversationModal from './NewConversationModal.vue';

const showNewConversationModal = ref(false);

const props = defineProps({
  conversations: {
    type: Array,
    default: () => [],
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
  activeConversationId: {
    type: Number,
    default: null,
  },
});
const store = useStore();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const currentUserId = useMapGetter('getCurrentUserID');

const sortedConversations = computed(() =>
  [...props.conversations].sort(
    (a, b) => new Date(b.last_activity_at || 0) - new Date(a.last_activity_at || 0)
  )
);

const openConversation = conversation => {
  router.push(
    accountScopedRoute('internal_conversations_show', {
      conversationId: conversation.id,
    })
  );
};

const openSelfChat = async () => {
  const existing = props.conversations.find(c => c.self_chat);
  if (existing) {
    openConversation(existing);
    return;
  }
  const conversation = await store.dispatch('internalConversations/openSelfChat');
  openConversation(conversation);
};

const getConversationAvatar = (conversation) => {
  if (conversation.self_chat) return null;
  // Se o backend já manda um avatar_url direto na conversa:
  if (conversation.avatar_url) return conversation.avatar_url;
  
  // Se o backend envia a lista de participants e você precisa achar o "outro":
  if (conversation.participants && Array.isArray(conversation.participants)) {
    const otherParticipant = conversation.participants.find(p => p.id !== currentUserId.value);
    return otherParticipant?.avatar_url || otherParticipant?.thumbnail || null;
  }
  return null;
};

</script>

<template>
  <aside class="flex flex-col w-72 h-full border-r border-n-weak flex-shrink-0">
    <div class="flex justify-between items-center p-3 border-b border-n-weak">
      <h2 class="text-sm font-medium text-n-slate-12">
        {{ $t('INTERNAL_CHAT.TITLE') }}
      </h2>
      <button
        class="flex justify-center items-center rounded-md size-7 hover:bg-n-alpha-2"
        :title="$t('INTERNAL_CHAT.SELF_CHAT_TOOLTIP')"
        @click="openSelfChat"
      >
        <span class="i-lucide-notebook-pen size-4" />
      </button>
      <button
            class="flex justify-center items-center rounded-md size-7 hover:bg-n-alpha-2"
            :title="$t('INTERNAL_CHAT.NEW_CONVERSATION')"
            @click="showNewConversationModal = true"
            >
            <span class="i-lucide-plus size-4" />
            </button>
    </div>

    <div class="overflow-y-auto flex-1">
      <p v-if="isFetching && !conversations.length" class="p-3 text-sm text-n-slate-11">
        {{ $t('INTERNAL_CHAT.LOADING') }}
      </p>
      <p v-else-if="!conversations.length" class="p-3 text-sm text-n-slate-11">
        {{ $t('INTERNAL_CHAT.EMPTY') }}
      </p>
      <ul v-else class="m-0 list-none">
        <li
          v-for="conversation in sortedConversations"
          :key="conversation.id"
          class="flex gap-2 items-center px-3 py-2 cursor-pointer hover:bg-n-alpha-2"
          :class="{ 'bg-n-alpha-2': conversation.id === activeConversationId }"
          @click="openConversation(conversation)"
        >
          <span
            class="flex justify-center items-center flex-shrink-0 rounded-full bg-n-brand/10 size-8 text-n-brand"
          >
            <div
            class="flex justify-center items-center flex-shrink-0 rounded-full size-8 overflow-hidden bg-n-brand/10 text-n-brand"
          >
            <span
              v-if="conversation.self_chat"
              class="i-lucide-notebook-pen size-4"
            />
            <img
              v-else-if="getConversationAvatar(conversation)"
              :src="getConversationAvatar(conversation)"
              :alt="conversation.display_name"
              class="size-full object-cover"
            />
            <span
              v-else
              class="i-lucide-user size-4"
            />
          </div>
          </span>
          <div class="flex-1 min-w-0">
            <p class="m-0 text-sm font-medium truncate text-n-slate-12">
              {{ conversation.display_name }}
            </p>
          </div>
          <span
            v-if="conversation.unread_count > 0"
            class="flex justify-center items-center px-1.5 h-5 text-xs font-medium text-white rounded-full bg-n-brand min-w-[20px]"
          >
            {{ conversation.unread_count }}
          </span>
        </li>
      </ul>
    </div>
  </aside>
  <NewConversationModal
  v-if="showNewConversationModal"
  @close="showNewConversationModal = false"
/>
</template>