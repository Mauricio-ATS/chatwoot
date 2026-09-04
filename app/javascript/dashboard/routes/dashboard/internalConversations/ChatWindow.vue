<script setup>
import { ref, computed, watch, onMounted, nextTick } from 'vue';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { DirectUpload } from 'activestorage';
import { setDirectUploadAuthHeaders } from 'dashboard/helper/directUploadsHelper';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const store = useStore();

const currentUserId = useMapGetter('getCurrentUserID');
const accountId = useMapGetter('getCurrentAccountId');

const messagesUiFlags = useMapGetter(
  'internalConversations/getMessagesUIFlags'
);

const fileInput = ref(null);
const attachedFiles = ref([]);
const messageContent = ref('');
const messagesContainer = ref(null);

const messages = computed(() =>
  store.getters['internalConversations/getMessagesByConversationId'](
    props.conversation.id
  )
);

const openFilePicker = () => {
  fileInput.value?.click();
};

const handleFileSelected = event => {
  const files = Array.from(event.target.files || []);

  if (!files.length) {
    return;
  }

  files.forEach(file => {
    const upload = new DirectUpload(
      file,
      `/api/v1/accounts/${accountId.value}/internal_conversations/${props.conversation.id}/direct_uploads`,
      {
        directUploadWillCreateBlobWithXHR: xhr => {
          setDirectUploadAuthHeaders(xhr);
        },
      }
    );

    upload.create((error, blob) => {
      if (error) {
        console.error('Erro no upload:', error);
        return;
      }

      attachedFiles.value.push({
        file,
        blobSignedId: blob.signed_id,
      });
    });
  });

  event.target.value = '';
};

const scrollToBottom = async () => {
  await nextTick();
  await nextTick();

  const el = messagesContainer.value;

  if (el) {
    el.scrollTop = el.scrollHeight;
  }
};

const fetchMessages = async () => {
  await store.dispatch(
    'internalConversations/fetchMessages',
    props.conversation.id
  );

  await scrollToBottom();
};

const sendMessage = async () => {
  const content = messageContent.value.trim();

  if (
    (!content && !attachedFiles.value.length) ||
    messagesUiFlags.value.isSending
  ) {
    return;
  }

  const attachments = attachedFiles.value.map(
    attachment => attachment.blobSignedId
  );

  messageContent.value = '';
  attachedFiles.value = [];

  await store.dispatch('internalConversations/sendMessage', {
    conversationId: props.conversation.id,
    content,
    attachments,
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
  if (!timestamp) {
    return '';
  }

  return new Date(timestamp).toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
  });
};

const formatFileSize = bytes => {
  if (!bytes) {
    return '';
  }

  if (bytes < 1024) {
    return `${bytes} B`;
  }

  if (bytes < 1024 * 1024) {
    return `${(bytes / 1024).toFixed(1)} KB`;
  }

  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
};

onMounted(fetchMessages);

watch(
  () => props.conversation.id,
  () => fetchMessages()
);
</script>

<template>
  <div class="flex flex-col flex-1 h-full min-w-0">
    <header
      class="flex items-center px-4 h-12 border-b border-n-weak flex-shrink-0"
    >
      <h3 class="m-0 text-sm font-medium text-n-slate-12">
        {{ conversation.display_name }}
      </h3>
    </header>

    <div ref="messagesContainer" class="overflow-y-auto flex-1 p-4">
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
          <p
            v-if="message.content"
            class="m-0 text-sm whitespace-pre-wrap break-words"
          >
            {{ message.content }}
          </p>

          <div
            v-if="message.attachments?.length"
            class="flex flex-col gap-2"
            :class="message.content ? 'mt-2' : ''"
          >
            <template
              v-for="attachment in message.attachments"
              :key="attachment.id"
            >
              <a
                v-if="attachment.file_type === 'image'"
                :href="attachment.data_url"
                target="_blank"
                rel="noopener noreferrer"
                class="block overflow-hidden rounded-lg"
              >
                <img
                  :src="attachment.thumb_url || attachment.data_url"
                  :alt="attachment.extension || 'Imagem'"
                  class="block max-w-full max-h-[320px] object-contain rounded-lg"
                />
              </a>

              <video
                v-else-if="attachment.file_type === 'video'"
                :src="attachment.data_url"
                controls
                preload="metadata"
                class="block max-w-full max-h-[320px] rounded-lg"
              />

              <audio
                v-else-if="attachment.file_type === 'audio'"
                :src="attachment.data_url"
                controls
                class="w-full min-w-[250px]"
              />

              <a
                v-else
                :href="attachment.data_url"
                target="_blank"
                rel="noopener noreferrer"
                class="flex items-center gap-3 p-3 rounded-lg bg-n-alpha-2 hover:bg-n-alpha-3 transition-colors"
              >
                <span class="i-lucide-file size-6 flex-shrink-0" />

                <div class="min-w-0">
                  <div class="text-sm font-medium truncate">
                    {{ attachment.extension || 'Arquivo' }}
                  </div>

                  <div
                    v-if="attachment.content_type || attachment.file_size"
                    class="text-xs opacity-70"
                  >
                    {{ attachment.content_type }}

                    <span v-if="attachment.file_size">
                      · {{ formatFileSize(attachment.file_size) }}
                    </span>
                  </div>
                </div>
              </a>
            </template>
          </div>

          <span class="block mt-1 text-[11px] opacity-70">
            {{ formatTime(message.created_at) }}
          </span>
        </div>
      </div>
    </div>

    <footer
      class="flex gap-2 items-end p-3 border-t border-n-weak flex-shrink-0"
    >
      <input
        ref="fileInput"
        type="file"
        multiple
        class="hidden"
        @change="handleFileSelected"
      />

      <button
        type="button"
        class="flex justify-center items-center rounded-lg size-9 bg-n-alpha-2 text-n-slate-12"
        @click="openFilePicker"
      >
        <span class="i-lucide-paperclip size-4" />
      </button>

      <div
        v-if="attachedFiles.length"
        class="flex flex-wrap gap-2 max-w-[40%]"
      >
        <div
          v-for="(attachment, index) in attachedFiles"
          :key="`${attachment.file.name}-${index}`"
          class="flex items-center gap-2 px-2 py-1 rounded bg-n-alpha-2 text-xs"
        >
          <span class="i-lucide-paperclip size-3" />

          <span class="truncate max-w-[160px]">
            {{ attachment.file.name }}
          </span>
        </div>
      </div>

      <textarea
        v-model="messageContent"
        rows="1"
        class="flex-1 px-3 py-2 text-sm rounded-lg border resize-none border-n-weak bg-n-background focus:outline-none focus:ring-1 focus:ring-n-brand"
        :placeholder="$t('INTERNAL_CHAT.MESSAGE_PLACEHOLDER')"
        @keydown="handleKeydown"
      />

      <button
        class="flex justify-center items-center rounded-lg size-9 bg-n-brand text-white disabled:opacity-50"
        :disabled="
          (!messageContent.trim() && !attachedFiles.length) ||
          messagesUiFlags.isSending
        "
        @click="sendMessage"
      >
        <span class="i-lucide-send size-4" />
      </button>
    </footer>
  </div>
</template>

