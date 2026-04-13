<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { getSupabaseClient } from '../lib/supabase'
import { CONTENT_ITEM_SELECT, mapContentRow, type ContentItemRow } from '../lib/contentItems'
import { CONTENT_TYPE_LABELS, type ContentItem, type ContentType, RESOURCE_TYPES } from '../types'

const supabase = getSupabaseClient()

const loading = ref(true)
const err = ref('')
const items = ref<ContentItem[]>([])
const typeFilter = ref<'all' | ContentType>('all')

const filtered = computed(() => {
  if (typeFilter.value === 'all') return items.value
  return items.value.filter((x) => x.type === typeFilter.value)
})

async function load() {
  if (!supabase) {
    loading.value = false
    err.value = '未配置 Supabase，无法加载列表。'
    return
  }
  loading.value = true
  err.value = ''
  const { data, error } = await supabase
    .from('content_items')
    .select(CONTENT_ITEM_SELECT)
    .eq('status', 'published')
    .in('type', [...RESOURCE_TYPES])
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
    const d = new Date(iso)
    return d.toLocaleString()
  } catch {
    return iso
  }
}
</script>

<template>
  <div class="browse">
    <header class="head">
      <h1>浏览资源</h1>
      <p class="sub">仅展示已发布内容；按类型筛选。</p>
    </header>

    <div class="filters">
      <label class="sr-only" for="type-filter">类型</label>
      <select id="type-filter" v-model="typeFilter" class="select">
        <option value="all">全部类型</option>
        <option v-for="t in RESOURCE_TYPES" :key="t" :value="t">{{ CONTENT_TYPE_LABELS[t] }}</option>
      </select>
    </div>

    <p v-if="loading" class="state">加载中…</p>
    <p v-else-if="err" class="state err">{{ err }}</p>
    <ul v-else class="list">
      <li v-for="item in filtered" :key="item.id" class="card">
        <RouterLink class="title" :to="{ name: 'item-detail', params: { id: item.id } }">{{ item.title }}</RouterLink>
        <div class="meta">
          <span class="tag">{{ CONTENT_TYPE_LABELS[item.type] }}</span>
          <span class="author">{{ item.author_name || '—' }}</span>
          <time :datetime="item.created_at">{{ formatTime(item.created_at) }}</time>
        </div>
      </li>
      <li v-if="!filtered.length" class="empty">暂无内容</li>
    </ul>
  </div>
</template>

<style scoped>
.browse {
  max-width: 800px;
}
.head h1 {
  margin: 0 0 6px;
  font-size: 1.5rem;
}
.sub {
  margin: 0 0 18px;
  color: var(--fg-muted);
  font-size: 0.95rem;
}
.filters {
  margin-bottom: 16px;
}
.select {
  padding: 8px 12px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--fg);
  font-size: 0.92rem;
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
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.card {
  padding: 16px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: var(--surface);
  box-shadow: var(--shadow);
}
.title {
  font-weight: 700;
  font-size: 1.05rem;
  color: var(--fg);
  text-decoration: none;
}
.title:hover {
  color: var(--accent);
}
.meta {
  margin-top: 8px;
  display: flex;
  flex-wrap: wrap;
  gap: 8px 14px;
  font-size: 0.86rem;
  color: var(--fg-muted);
}
.tag {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 6px;
  background: var(--surface-2);
  color: var(--fg);
  font-weight: 600;
}
.empty {
  padding: 24px;
  text-align: center;
  color: var(--fg-muted);
}
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
</style>
