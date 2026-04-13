<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { mumu } from '../content/mumuCopy'
import { getSupabaseClient } from '../lib/supabase'
import { CONTENT_ITEM_SELECT, mapContentRow, type ContentItemRow } from '../lib/contentItems'
import type { ContentItem } from '../types'

const supabase = getSupabaseClient()
const loading = ref(true)
const err = ref('')
const items = ref<ContentItem[]>([])

async function load() {
  if (!supabase) {
    loading.value = false
    err.value = mumu.noSupabase
    return
  }
  loading.value = true
  err.value = ''
  const { data, error } = await supabase
    .from('content_items')
    .select(CONTENT_ITEM_SELECT)
    .eq('status', 'published')
    .eq('type', 'announcement')
    .order('created_at', { ascending: false })
  loading.value = false
  if (error) {
    err.value = error.message
    return
  }
  items.value = (data ?? []).map((x) => mapContentRow(x as ContentItemRow))
}

onMounted(load)

function formatTime(iso: string) {
  try {
    return new Date(iso).toLocaleString()
  } catch {
    return iso
  }
}
</script>

<template>
  <div class="page">
    <header class="head">
      <h1>{{ mumu.announcementsTitle }}</h1>
      <p class="sub">{{ mumu.announcementsSub }}</p>
    </header>

    <p v-if="loading" class="state">{{ mumu.loading }}</p>
    <p v-else-if="err" class="state err">{{ err }}</p>
    <ul v-else-if="items.length" class="list">
      <li v-for="a in items" :key="a.id" class="row">
        <RouterLink :to="{ name: 'item-detail', params: { id: a.id } }" class="link">{{ a.title }}</RouterLink>
        <time class="time" :datetime="a.created_at">{{ formatTime(a.created_at) }}</time>
      </li>
    </ul>
    <p v-else class="empty">{{ mumu.emptyAnnouncements }}</p>
  </div>
</template>

<style scoped>
.head h1 {
  margin: 0 0 6px;
}
.sub {
  margin: 0 0 20px;
  color: var(--fg-muted);
  line-height: 1.55;
}
.state {
  color: var(--fg-muted);
}
.state.err {
  color: var(--danger);
}
.list {
  list-style: none;
  margin: 0;
  padding: 0;
}
.row {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 14px 0;
  border-bottom: 1px solid var(--border);
}
.link {
  font-weight: 600;
  color: var(--fg);
  text-decoration: none;
}
.link:hover {
  color: var(--accent);
}
.time {
  font-size: 0.85rem;
  color: var(--fg-muted);
}
.empty {
  padding: 24px 0;
  color: var(--fg-muted);
  line-height: 1.6;
}
</style>
