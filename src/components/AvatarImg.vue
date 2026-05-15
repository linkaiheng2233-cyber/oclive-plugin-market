<script setup lang="ts">
import { ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { resolveAvatarForDisplay } from '../lib/avatarDisplayUrl'
import { getSupabaseClient } from '../lib/supabase'

const { t } = useI18n()

const props = defineProps<{
  storedUrl: string
  imgClass?: string
}>()

const src = ref('')

watch(
  () => props.storedUrl,
  async (u) => {
    src.value = await resolveAvatarForDisplay(getSupabaseClient(), u)
  },
  { immediate: true }
)
</script>

<template>
  <img
    v-if="src"
    :src="src"
    :class="imgClass"
    :alt="t('market.avatarAlt')"
    referrerpolicy="no-referrer"
    loading="lazy"
    decoding="async"
  />
</template>
