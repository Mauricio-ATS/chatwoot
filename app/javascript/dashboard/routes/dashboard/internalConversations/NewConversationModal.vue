<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';

const emit = defineEmits(['close']);

const store = useStore();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const currentUserId = useMapGetter('getCurrentUserID');
const agents = useMapGetter('agents/getAgents');
const isCreating = useMapGetter('internalConversations/getUIFlags');

const searchTerm = ref('');

const filteredAgents = computed(() => {
  return agents.value
    .filter(agent => agent.id !== currentUserId.value)
    .filter(agent =>
      agent.name.toLowerCase().includes(searchTerm.value.toLowerCase())
    );
});

const selectAgent = async agent => {
  const conversation = await store.dispatch(
    'internalConversations/openDirect',
    agent.id
  );
  router.push(
    accountScopedRoute('internal_conversations_show', {
      conversationId: conversation.id,
    })
  );
  emit('close');
};
</script>

<template>
  <div
    class="flex fixed inset-0 z-50 justify-center items-center bg-black/40"
    @click.self="emit('close')"
  >
    <div class="flex flex-col w-80 max-h-[28rem] rounded-lg bg-n-background shadow-lg">
      <header class="flex justify-between items-center p-3 border-b border-n-weak">
        <h3 class="m-0 text-sm font-medium text-n-slate-12">
          {{ $t('INTERNAL_CHAT.NEW_CONVERSATION') }}
        </h3>
        <button
          class="flex justify-center items-center rounded-md size-7 hover:bg-n-alpha-2"
          @click="emit('close')"
        >
          <span class="i-lucide-x size-4" />
        </button>
      </header>

      <div class="p-3 border-b border-n-weak">
        <input
          v-model="searchTerm"
          type="text"
          class="px-3 py-2 w-full text-sm rounded-lg border border-n-weak bg-n-background focus:outline-none focus:ring-1 focus:ring-n-brand"
          :placeholder="$t('INTERNAL_CHAT.SEARCH_AGENT_PLACEHOLDER')"
        />
      </div>

      <ul class="overflow-y-auto flex-1 m-0 list-none">
        <li
          v-for="agent in filteredAgents"
          :key="agent.id"
          class="flex gap-2 items-center px-3 py-2 cursor-pointer hover:bg-n-alpha-2"
          @click="selectAgent(agent)"
        >
          <div class="flex justify-center items-center flex-shrink-0 rounded-full size-8 overflow-hidden bg-n-brand/10 text-n-brand">
            <img
              v-if="agent.avatar_url || agent.thumbnail"
              :src="agent.avatar_url || agent.thumbnail"
              :alt="agent.name"
              class="size-full object-cover"
            />
            <span v-else class="i-lucide-user size-4" />
          </div>

          <span class="text-sm text-n-slate-12">{{ agent.name }}</span>
        </li>
        <li
          v-if="!filteredAgents.length"
          class="p-3 text-sm text-center text-n-slate-11"
        >
          {{ $t('INTERNAL_CHAT.NO_AGENTS_FOUND') }}
        </li>
      </ul>

    </div>
  </div>
</template>