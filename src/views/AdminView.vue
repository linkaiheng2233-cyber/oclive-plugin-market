<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useAuthContext } from '../composables/useAuthContext'
import { getSupabaseClient } from '../lib/supabase'
import type { ContentItem, ContentStatus, ContentType } from '../types'

const supabase = getSupabaseClient()
const { isAdmin } = useAuthContext()

const loading = ref(false)
const err = ref('')
const items = ref<ContentItem[]>([])
const typeFilter = ref<'all' | ContentType>('all')
const statusFilter = ref<'all' | ContentStatus>('all')

const filtered = computed(() =>
  items.value.filter((x) => {
    const typeOk = typeFilter.value === 'all' || x.type === typeFilter.value
    const statusOk = statusFilter.value === 'all' || x.status === statusFilter.value
    return typeOk && statusOk
  })
)

async function loadAll() {
  if (!supabase || !isAdmin.value) return
  loading.value = true
  err.value = ''
  const { data, error } = await supabase
    .from('content_items')
    .select('*')
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
  if (!window.confirm(`管理员删除「${item.title}」?`)) return
  const { error } = await supabase.from('content_items').delete().eq('id', item.id)
  if (error) {
    err.value = error.message
    return
  }
  items.value = items.value.filter((x) => x.id !== item.id)
}

onMounted(() => {
  void loadAll()
})
</script>

<template>
  <div class="page-head">
    <h1>管理员面板</h1>
    <p class="sub">可查看所有内容并执行下架/恢复、删除操作。</p>
  </div>

  <p v-if="!isAdmin" class="state err">你不是管理员，无法访问此页面。</p>
  <template v-else>
    <div class="filters">
      <select v-model="typeFilter">
        <option value="all">全部类型</option>
        <option value="character">角色包</option>
        <option value="plugin">插件</option>
        <option value="module">模块</option>
        <option value="branch">分支</option>
      </select>
      <select v-model="statusFilter">
        <option value="all">全部状态</option>
        <option value="published">published</option>
        <option value="hidden">hidden</option>
      </select>
    </div>

    <p v-if="loading" class="state">加载中...</p>
    <p v-else-if="err" class="state err">{{ err }}</p>
    <ul v-else-if="filtered.length" class="list">
      <li v-for="item in filtered" :key="item.id" class="row">
        <div>
          <p class="title">{{ item.title }}</p>
          <p class="tiny">{{ item.type }} · {{ item.author_id }} · {{ item.status }}</p>
        </div>
        <div class="ops">
          <button @click="toggleStatus(item)">{{ item.status === 'published' ? '下架' : '恢复' }}</button>
          <button class="danger" @click="removeItem(item)">删除</button>
        </div>
      </li>
    </ul>
    <p v-else class="state">暂无数据。</p>
  </template>
</template>

<style scoped>
.page-head {
  margin-bottom: 16px;
}
.sub {
  margin: 0;
  color: var(--fg-muted);
}
.filters {
  display: flex;
  gap: 10px;
  margin: 14px 0;
}
.filters select {
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 7px 10px;
  background: var(--surface);
}
.list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 10px;
}
.row {
  border: 1px solid var(--border);
  border-radius: 12px;
  background: var(--surface);
  padding: 12px;
  display: flex;
  justify-content: space-between;
  gap: 12px;
}
.title {
  margin: 0 0 4px;
  font-weight: 700;
}
.tiny {
  margin: 0;
  font-size: 0.8rem;
  color: var(--fg-soft);
}
.ops {
  display: flex;
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

