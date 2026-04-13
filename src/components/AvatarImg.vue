<script setup lang="ts">
import { ref, watch } from 'vue'
import { resolveAvatarForDisplay } from '../lib/avatarDisplayUrl'
import { getSupabaseClient } from '../lib/supabase'

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
    alt="头像"
    referrerpolicy="no-referrer"
    loading="lazy"
    decoding="async"
  />
</template>
