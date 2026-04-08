<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useAuthContext } from '../composables/useAuthContext'
import { getSupabaseClient } from '../lib/supabase'
import type { ContentItem, ContentStatus, ContentType } from '../types'

const supabase = getSupabaseClient()
const { userId, userEmail } = useAuthContext()

const loading = ref(false)
const err = ref('')
const items = ref<ContentItem[]>([])
const typeFilter = ref<'all' | ContentType>('all')

const filtered = computed(() =>
  typeFilter.value === 'all' ? items.value : items.value.filter((x) => x.type === typeFilter.value)
)

function asList(meta: unknown) {
  try {
    return JSON.stringify(meta, null, 2)
  } catch {
    return '{}'
  }
}

async function loadMine() {
  if (!supabase || !userId.value) return
  loading.value = true
  err.value = ''
  const { data, error } = await supabase
    .from('content_items')
    .select('*')
    .eq('author_id', userId.value)
    .order('updated_at', { ascending: false })
  loading.value = false
  if (error) {
    err.value = error.message
    return
  }
  items.value = (data ?? []) as ContentItem[]
}

async function toggleStatus(item: ContentItem) {
  if (!supabase) return
  const next: ContentStatus = item.status === 'published' ? 'hidden' : 'published'
  const { error } = await supabase.from('content_items').update({ status: next }).eq('id', item.id)
  if (error) {
    err.value = error.message
    return
  }
  item.status = next
}

async function removeItem(item: ContentItem) {
  if (!supabase) return
  if (!window.confirm(`确定删除「${item.title}」吗？`)) return
  const { error } = await supabase.from('content_items').delete().eq('id', item.id)
  if (error) {
    err.value = error.message
    return
  }
  items.value = items.value.filter((x) => x.id !== item.id)
}

async function editItem(item: ContentItem) {
  if (!supabase) return
  const title = window.prompt('标题', item.title)
  if (!title) return
  const description = window.prompt('简介', item.description)
  if (!description) return
  const tagsStr = window.prompt('标签（逗号分隔）', item.tags.join(','))
  if (tagsStr == null) return
  const version = window.prompt('版本号', item.version || 'v1.0.0')
  if (!version) return
  const metadataStr = window.prompt('metadata JSON', asList(item.metadata))
  if (metadataStr == null) return
  let metadata: Record<string, unknown> = {}
  try {
    metadata = JSON.parse(metadataStr)
  } catch {
    window.alert('metadata 不是合法 JSON')
    return
  }

  const { error } = await supabase
    .from('content_items')
    .update({
      title,
      description,
      tags: tagsStr
        .split(',')
        .map((x) => x.trim())
        .filter(Boolean),
      version,
      metadata,
    })
    .eq('id', item.id)
  if (error) {
    err.value = error.message
    return
  }
  Object.assign(item, {
    title,
    description,
    tags: tagsStr
      .split(',')
      .map((x) => x.trim())
      .filter(Boolean),
    version,
    metadata,
  })
}

onMounted(() => {
  void loadMine()
})
</script>

<template>
  <div class="page-head">
    <h1>我的上传管理</h1>
    <p class="sub">你可以编辑、下架/恢复、删除自己的角色包、插件、模块与分支。</p>
    <p v-if="userEmail" class="hint">当前账号：{{ userEmail }}</p>
  </div>

  <p v-if="!userId" class="state err">请先登录后再管理上传内容。</p>
  <template v-else>
    <div class="tabs">
      <button class="tab" :class="{ active: typeFilter === 'all' }" @click="typeFilter = 'all'">全部</button>
      <button class="tab" :class="{ active: typeFilter === 'character' }" @click="typeFilter = 'character'">
        角色包
      </button>
      <button class="tab" :class="{ active: typeFilter === 'plugin' }" @click="typeFilter = 'plugin'">插件</button>
      <button class="tab" :class="{ active: typeFilter === 'module' }" @click="typeFilter = 'module'">模块</button>
      <button class="tab" :class="{ active: typeFilter === 'branch' }" @click="typeFilter = 'branch'">分支</button>
    </div>

    <p v-if="loading" class="state">加载中...</p>
    <p v-else-if="err" class="state err">{{ err }}</p>
    <ul v-else-if="filtered.length" class="list">
      <li v-for="item in filtered" :key="item.id" class="row">
        <div class="meta">
          <p class="title">{{ item.title }}</p>
          <p class="desc">{{ item.description }}</p>
          <p class="tiny">
            {{ item.type }} · {{ item.version }} ·
            <span :class="item.status === 'published' ? 'ok' : 'warn'">{{ item.status }}</span>
          </p>
        </div>
        <div class="ops">
          <button @click="editItem(item)">编辑</button>
          <button @click="toggleStatus(item)">{{ item.status === 'published' ? '下架' : '恢复' }}</button>
          <button class="danger" @click="removeItem(item)">删除</button>
        </div>
      </li>
    </ul>
    <p v-else class="state">暂无内容。</p>
  </template>
</template>

<style scoped>
.page-head {
  margin-bottom: 16px;
}
h1 {
  margin: 0 0 8px;
}
.sub {
  margin: 0 0 4px;
  color: var(--fg-muted);
}
.hint {
  margin: 0;
  color: var(--fg-soft);
  font-size: 0.85rem;
}
.tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 0 0 14px;
}
.tab {
  border: 1px solid var(--border);
  border-radius: 999px;
  background: var(--surface);
  color: var(--fg-muted);
  padding: 6px 12px;
  cursor: pointer;
}
.tab.active {
  border-color: var(--accent-soft);
  color: var(--accent);
}
.list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  gap: 10px;
}
.row {
  border: 1px solid var(--border);
  border-radius: 12px;
  background: var(--surface);
  padding: 12px;
  display: flex;
  gap: 12px;
  justify-content: space-between;
  align-items: flex-start;
}
.title {
  margin: 0 0 4px;
  font-weight: 700;
}
.desc {
  margin: 0 0 4px;
  color: var(--fg-muted);
}
.tiny {
  margin: 0;
  font-size: 0.8rem;
  color: var(--fg-soft);
}
.ok {
  color: #2e7d32;
}
.warn {
  color: #b26a00;
}
.ops {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.ops button {
  border: 1px solid var(--border);
  background: var(--surface-2);
  border-radius: 8px;
  padding: 6px 10px;
  cursor: pointer;
}
.ops .danger {
  color: #a33f2f;
}
.state.err {
  color: var(--danger);
}
</style>

