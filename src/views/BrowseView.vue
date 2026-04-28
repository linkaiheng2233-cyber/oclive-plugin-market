<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { mumu } from '../content/mumuCopy'
import { getSupabaseClient } from '../lib/supabase'
import { CONTENT_ITEM_SELECT, mapContentRow, type ContentItemRow } from '../lib/contentItems'
import { CONTENT_TYPE_LABELS, type ContentItem, type ContentType, RESOURCE_TYPES } from '../types'

const supabase = getSupabaseClient()

const loading = ref(true)
const err = ref('')
const items = ref<ContentItem[]>([])
const typeFilter = ref<'all' | ContentType>('all')
const searchQuery = ref('')
const sortMode = ref<'newest' | 'oldest' | 'title'>('newest')

const byType = computed(() => {
  if (typeFilter.value === 'all') return items.value
  return items.value.filter((x) => x.type === typeFilter.value)
})

const filtered = computed(() => {
  let list = byType.value
  const q = searchQuery.value.trim().toLowerCase()
  if (q) {
    list = list.filter((x) => {
      const hay = [x.title, x.description, ...(x.tags || [])].join(' ').toLowerCase()
      return hay.includes(q)
    })
  }
  const arr = [...list]
  if (sortMode.value === 'newest') {
    arr.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
  } else if (sortMode.value === 'oldest') {
    arr.sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime())
  } else {
    arr.sort((a, b) => a.title.localeCompare(b.title, 'zh-CN'))
  }
  return arr
})

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
      <h1>{{ mumu.browseTitle }}</h1>
      <p class="sub">{{ mumu.browseSub }}</p>
    </header>

    <div class="toolbar">
      <label class="sr-only" for="browse-search">搜索</label>
      <input
        id="browse-search"
        v-model="searchQuery"
        type="search"
        class="search"
        :placeholder="mumu.browseSearchPlaceholder"
        autocomplete="off"
      />
      <div class="toolbar-row">
        <label class="sr-only" for="type-filter">类型</label>
        <select id="type-filter" v-model="typeFilter" class="select">
          <option value="all">全部类型</option>
          <option v-for="t in RESOURCE_TYPES" :key="t" :value="t">{{ CONTENT_TYPE_LABELS[t] }}</option>
        </select>
        <label class="sr-only" for="sort-mode">排序</label>
        <select id="sort-mode" v-model="sortMode" class="select">
          <option value="newest">{{ mumu.sortNewest }}</option>
          <option value="oldest">{{ mumu.sortOldest }}</option>
          <option value="title">{{ mumu.sortTitle }}</option>
        </select>
      </div>
    </div>

    <p v-if="loading" class="state">{{ mumu.loading }}</p>
    <p v-else-if="err" class="state err">{{ err }}</p>
    <template v-else>
      <ul v-if="filtered.length" class="list">
        <li v-for="item in filtered" :key="item.id" class="card">
          <RouterLink class="title" :to="{ name: 'item-detail', params: { id: item.id } }">{{ item.title }}</RouterLink>
          <div class="meta">
            <span class="tag">{{ CONTENT_TYPE_LABELS[item.type] }}</span>
            <span class="author">{{ item.author_name || '—' }}</span>
            <time :datetime="item.created_at">{{ formatTime(item.created_at) }}</time>
          </div>
        </li>
      </ul>
      <div v-else-if="!items.length" class="empty-box">
        <p>{{ mumu.emptyBrowse }}</p>
        <RouterLink class="cta" to="/submit">去发布</RouterLink>
      </div>
      <div v-else class="empty-box">
        <p>{{ mumu.noSearchResults }}</p>
      </div>
    </template>
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
  line-height: 1.55;
}
.index-link {
  margin: 0 0 12px;
  font-size: 0.88rem;
}
.index-link a {
  color: var(--accent);
  text-decoration: none;
}
.index-link a:hover {
  text-decoration: underline;
}
.toolbar {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 18px;
}
.toolbar-row {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}
.search {
  width: 100%;
  padding: 10px 14px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--fg);
  font-size: 0.95rem;
  box-sizing: border-box;
}
.search:focus {
  outline: 2px solid color-mix(in srgb, var(--accent) 35%, transparent);
  outline-offset: 1px;
}
.select {
  padding: 8px 12px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--fg);
  font-size: 0.92rem;
  min-width: 0;
  flex: 1 1 140px;
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
.empty-box {
  padding: 28px 20px;
  text-align: center;
  border-radius: 14px;
  border: 1px dashed var(--border);
  background: color-mix(in srgb, var(--surface) 92%, var(--bg));
}
.empty-box p {
  margin: 0 0 14px;
  color: var(--fg-muted);
  line-height: 1.6;
}
.cta {
  display: inline-block;
  padding: 8px 18px;
  border-radius: 999px;
  background: var(--accent);
  color: var(--accent-fg);
  font-weight: 600;
  text-decoration: none;
  font-size: 0.92rem;
}
.cta:hover {
  filter: brightness(1.05);
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
