<template>
  <woot-modal
    modal-type="right-aligned"
    show
    @close="onClose"
  >
    <div class="forward-message flex flex-col h-full bg-white dark:bg-slate-900">
      <woot-modal-header
        :title="$t('FORWARD_MESSAGE.TITLE')"
        :description="$t('FORWARD_MESSAGE.DESCRIPTION')"
      />

      <div class="flex-1 flex flex-col min-h-0 px-6 py-4">
        <div class="mb-4">
          <label class="block mb-1 text-xs font-medium text-slate-700 dark:text-slate-200">
            {{ $t('FORWARD_MESSAGE.SEARCH_LABEL') }}
          </label>
          <input
            v-model="searchQuery"
            type="search"
            class="w-full rounded-md border-slate-200 dark:border-slate-700 dark:bg-slate-800"
            :placeholder="$t('FORWARD_MESSAGE.SEARCH_PLACEHOLDER')"
            @input="onInputSearch"
          />
        </div>

        <div
          ref="contactListContainer"
          class="flex-1 min-h-0 overflow-y-auto border border-slate-100 dark:border-slate-800 rounded-md divide-y divide-slate-100 dark:divide-slate-800"
          @scroll="handleScroll"
        >
          <div
            v-for="contact in contacts"
            :key="contact.id"
            class="flex items-center justify-between p-3 hover:bg-slate-50 dark:hover:bg-slate-800/50 cursor-pointer"
            @click="toggleContactSelection(contact.id)"
          >
            <div class="flex items-center gap-3 min-w-0 flex-1">
              <input
                type="checkbox"
                class="rounded border-slate-300 text-woot-500 focus:ring-woot-500"
                :value="contact.id"
                :checked="selectedContactIds.includes(contact.id)"
                @click.stop
                @change="toggleContactSelection(contact.id)"
              />

              <div class="w-9 h-9 rounded-full overflow-hidden bg-slate-100 flex-shrink-0 flex items-center justify-center">
                <img
                  v-if="contact.thumbnail"
                  :src="contact.thumbnail"
                  :alt="contact.name"
                  class="w-full h-full object-cover"
                />
                <span v-else class="text-sm font-medium text-slate-600">
                  {{ contact.name ? contact.name.charAt(0).toUpperCase() : '?' }}
                </span>
              </div>

              <div class="min-w-0 flex-1">
                <p class="text-sm font-medium text-slate-800 dark:text-slate-100 truncate">
                  {{ contact.name }}
                </p>
                <p class="text-xs text-slate-500 dark:text-slate-400 truncate">
                  {{ contact.phone_number || contact.email || '-' }}
                </p>
              </div>
            </div>

            <div class="text-xs text-slate-400 whitespace-nowrap ml-2">
              <time-ago
                :last-activity-timestamp="contact.last_activity_at"
                :created-at-timestamp="contact.created_at"
              />
            </div>
          </div>

          <div
            v-if="showEmptyState"
            class="p-8 text-center text-sm text-slate-500"
          >
            {{ $t('FORWARD_MESSAGE.EMPTY_STATE') }}
          </div>
        </div>
      </div>

      <div class="flex justify-end gap-2 px-6 py-4 border-t border-slate-100 dark:border-slate-800">
        <button
          type="button"
          class="button clear secondary"
          @click="onClose"
        >
          {{ $t('FORWARD_MESSAGE.CANCEL') }}
        </button>

        <button
          type="button"
          class="button success"
          :class="{ loading: isSubmitting }"
          :disabled="!selectedContactIds.length || isSubmitting"
          @click="onSubmit"
        >
          {{ $t('FORWARD_MESSAGE.SUBMIT') }}
        </button>
      </div>
    </div>
  </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
import { debounce } from '@chatwoot/utils';
import { useAlert } from 'dashboard/composables';
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';

export default {
  name: 'ForwardMessageModal',
  components: {
    UserAvatarWithName,
    TimeAgo,
  },
  props: {
    message: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      searchQuery: '',
      selectedContactIds: [],
      currentPage: 1,
      isSubmitting: false,
    };
  },

  computed: {
    ...mapGetters({
      contacts: 'contacts/getContacts',
      uiFlags: 'contacts/getUIFlags',
      meta: 'contacts/getMeta',
    }),

    showEmptyState() {
      return !this.uiFlags?.isFetching && this.contacts.length === 0;
    },
  },

  mounted() {
    this.fetchContacts(1);
  },

  methods: {
    onClose() {
      this.$emit('close');
    },

    toggleContactSelection(contactId) {
      if (this.selectedContactIds.includes(contactId)) {
        this.selectedContactIds = this.selectedContactIds.filter(id => id !== contactId);
      } else {
        this.selectedContactIds.push(contactId);
      }
    },

    fetchContacts(page = 1) {
      this.currentPage = page;
      let cleanQuery = this.searchQuery.trim();
      if (cleanQuery.startsWith('+')) {
        cleanQuery = cleanQuery.substring(1);
      }

      const payload = {
        page: this.currentPage,
        sortAttr: '-last_activity_at',
      };

      if (cleanQuery) {
        payload.search = cleanQuery;
        this.$store.dispatch('contacts/search', payload);
      } else {
        this.$store.dispatch('contacts/get', payload);
      }
    },

    onInputSearch: debounce(function() {
      this.fetchContacts(1);
    }, 300),

    handleScroll() {
      const container = this.$refs.contactListContainer;
      if (!container) return;

      const isAtBottom = container.scrollTop + container.clientHeight >= container.scrollHeight - 20;
      const hasMorePages = this.meta?.hasMorePages;

      if (isAtBottom && hasMorePages && !this.uiFlags?.isFetching) {
        this.fetchContacts(this.currentPage + 1);
      }
    },

    async onSubmit() {
        console.log('[ForwardModal] 1. Tentando enviar:', {
            conversationId: this.message.conversation_id,
            messageId: this.message.id,
            contactIds: this.selectedContactIds,
        });

        if (!this.selectedContactIds.length || this.isSubmitting) return;
        this.isSubmitting = true;

        try {
            const res = await this.$store.dispatch('forwardMessage', {
            conversationId: this.message.conversation_id,
            messageId: this.message.id,
            contactIds: this.selectedContactIds,
            });
            console.log('[ForwardModal] 2. Sucesso no Dispatch:', res);
            useAlert(this.$t('FORWARD_MESSAGE.SUCCESS'));
            this.onClose();
        } catch (error) {
            console.error('[ForwardModal] Erro ao disparar action:', error);
            useAlert(this.$t('FORWARD_MESSAGE.ERROR'));
        } finally {
            this.isSubmitting = false;
        }
    }
  },
};
</script>