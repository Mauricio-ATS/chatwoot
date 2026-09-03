import { frontendURL } from '../../../helper/URLHelper.js';
import InternalConversationsHome from './InternalConversationsHome.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/internal-chat'),
    name: 'internal_conversations_index',
    component: InternalConversationsHome,
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
  },
  {
    path: frontendURL('accounts/:accountId/internal-chat/:conversationId'),
    name: 'internal_conversations_show',
    component: InternalConversationsHome,
    props: true,
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
  },
];