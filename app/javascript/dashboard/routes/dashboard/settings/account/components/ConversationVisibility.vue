<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import Switch from 'next/switch/Switch.vue';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();

const isEnabled = ref(false);
const isSubmitting = ref(false);

watch(
  currentAccount,
  account => {
    isEnabled.value =
      account?.settings?.agents_can_only_see_assigned_conversations ?? false;
  },
  { immediate: true }
);

const toggleConversationVisibility = async () => {
  try {
    isSubmitting.value = true;
    console.log('isEnabled:', isEnabled.value);
    await updateAccount(
      {
        agents_can_only_see_assigned_conversations: isEnabled.value,
      },
      { silent: true }
    );

    useAlert(t('GENERAL_SETTINGS.FORM.CONVERSATION_VISIBILITY.API.SUCCESS'));
  } catch (error) {
    isEnabled.value = !isEnabled.value;
    useAlert(t('GENERAL_SETTINGS.FORM.CONVERSATION_VISIBILITY.API.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div class="flex justify-between items-center w-full">
    <div>
      <h3>
        {{ t('GENERAL_SETTINGS.FORM.CONVERSATION_VISIBILITY.TITLE') }}
      </h3>

      <p>
        {{ t('GENERAL_SETTINGS.FORM.CONVERSATION_VISIBILITY.NOTE') }}
      </p>
    </div>

    <Switch
      v-model="isEnabled"
      :disabled="isSubmitting"
      @change="toggleConversationVisibility"
    />
  </div>
</template>