<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useAuthContext } from '../composables/useAuthContext'
import { getSupabaseClient } from '../lib/supabase'
import type { ContentItem, ContentStatus, ContentType } from '../types'

const supabase = getSupabaseClient()
const { isAdmin, userId } = useAuthContext()

const loading = ref(false)
const err = ref('')
const items = ref<ContentItem[]>([])
const typeFilter = ref<'all' | ContentType>('all')
const statusFilter = ref<'all' | ContentStatus>('all')

type Tab = 'content' | 'forum'
const tab = ref<Tab>('content')

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

type ForumReportTargetType = 'thread' | 'post'
type ForumReportStatus = 'open' | 'handled' | 'rejected'

type ForumReportRow = {
  id: string
  target_type: ForumReportTargetType
  target_id: string
  reporter_id: string
  reason_code: string
  reason_text: string
  status: ForumReportStatus
  created_at: string
  updated_at: string
}

const forumLoading = ref(false)
const forumErr = ref('')
const reportStatus = ref<ForumReportStatus | 'all'>('open')
const reports = ref<ForumReportRow[]>([])
const targets = ref<Record<string, any>>({})

function keyOf(t: ForumReportTargetType, id: string) {
  return `${t}:${id}`
}

async function loadForumReports() {
  if (!supabase || !isAdmin.value) return
  forumLoading.value = true
  forumErr.value = ''
  targets.value = {}

  let q = supabase.from('forum_reports').select('*').order('updated_at', { ascending: false })
  if (reportStatus.value !== 'all') q = q.eq('status', reportStatus.value)

  const { data, error } = await q
  forumLoading.value = false
  if (error) {
    forumErr.value = error.message
    return
  }
  reports.value = (data ?? []) as ForumReportRow[]

  const threadIds = Array.from(new Set(reports.value.filter((r) => r.target_type === 'thread').map((r) => r.target_id)))
  const postIds = Array.from(new Set(reports.value.filter((r) => r.target_type === 'post').map((r) => r.target_id)))

  if (threadIds.length) {
    const { data: t } = await supabase.from('forum_threads').select('id,title,status,author_id,category_id').in('id', threadIds)
    for (const row of (t ?? []) as any[]) targets.value[keyOf('thread', row.id)] = row
  }
  if (postIds.length) {
    const { data: p } = await supabase.from('forum_posts').select('id,thread_id,floor,status,author_id,content').in('id', postIds)
    for (const row of (p ?? []) as any[]) targets.value[keyOf('post', row.id)] = row
  }
}

async function addModerationAction(action: string, targetType: string, targetId: string, note: string) {
  if (!supabase || !userId.value) return
  await supabase.from('forum_moderation_actions').insert({
    actor_id: userId.value,
    action,
    target_type: targetType,
    target_id: targetId,
    note: note.trim(),
  })
}

async function setReportStatus(r: ForumReportRow, next: ForumReportStatus, note: string) {
  if (!supabase) return
  const { error } = await supabase.from('forum_reports').update({ status: next }).eq('id', r.id)
  if (error) {
    forumErr.value = error.message
    return
  }
  await addModerationAction('note', 'report', r.id, `${next}: ${note}`.trim())
  r.status = next
}

async function hideThread(r: ForumReportRow) {
  if (!supabase) return
  const note = window.prompt('处置说明（会写入审计记录）', '下架该主题') ?? ''
  const { error } = await supabase.from('forum_threads').update({ status: 'hidden' }).eq('id', r.target_id)
  if (error) {
    forumErr.value = error.message
    return
  }
  await addModerationAction('hide_thread', 'thread', r.target_id, note)
  await setReportStatus(r, 'handled', note)
  await loadForumReports()
}

async function lockThread(r: ForumReportRow) {
  if (!supabase) return
  const note = window.prompt('处置说明（会写入审计记录）', '锁定该主题') ?? ''
  const { error } = await supabase.from('forum_threads').update({ status: 'locked' }).eq('id', r.target_id)
  if (error) {
    forumErr.value = error.message
    return
  }
  await addModerationAction('lock_thread', 'thread', r.target_id, note)
  await setReportStatus(r, 'handled', note)
  await loadForumReports()
}

async function hidePost(r: ForumReportRow) {
  if (!supabase) return
  const note = window.prompt('处置说明（会写入审计记录）', '隐藏该楼层') ?? ''
  const { error } = await supabase.from('forum_posts').update({ status: 'hidden' }).eq('id', r.target_id)
  if (error) {
    forumErr.value = error.message
    return
  }
  await addModerationAction('hide_post', 'post', r.target_id, note)
  await setReportStatus(r, 'handled', note)
  await loadForumReports()
}

async function rejectReport(r: ForumReportRow) {
  const note = window.prompt('驳回原因（会写入审计记录）', '不成立') ?? ''
  await setReportStatus(r, 'rejected', note)
  await loadForumReports()
}

onMounted(() => {
  void loadAll()
})
</script>

<template>
  <div class="page-head">
    <h1>管理员面板</h1>
    <p class="sub">可查看所有内容并执行下架/恢复、删除、论坛举报处置等操作。</p>
  </div>

  <p v-if="!isAdmin" class="state err">你不是管理员，无法访问此页面。</p>
  <template v-else>
    <div class="tabs">
      <button class="tab" :class="{ 'tab--active': tab === 'content' }" @click="tab = 'content'">内容库</button>
      <button class="tab" :class="{ 'tab--active': tab === 'forum' }" @click="tab = 'forum'; loadForumReports()">
        论坛举报
      </button>
    </div>

    <section v-if="tab === 'content'">
      <div class="filters">
        <select v-model="typeFilter">
          <option value="all">全部类型</option>
          <option value="character">角色包</option>
          <option value="announcement">公告</option>
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
    </section>

    <section v-else class="forum">
      <div class="filters">
        <select v-model="reportStatus" @change="loadForumReports">
          <option value="open">open</option>
          <option value="handled">handled</option>
          <option value="rejected">rejected</option>
          <option value="all">all</option>
        </select>
        <button @click="loadForumReports">刷新</button>
      </div>

      <p v-if="forumLoading" class="state">加载中...</p>
      <p v-else-if="forumErr" class="state err">{{ forumErr }}</p>
      <ul v-else-if="reports.length" class="list">
        <li v-for="r in reports" :key="r.id" class="row">
          <div class="rep">
            <p class="title">
              <strong>[{{ r.status }}]</strong>
              {{ r.reason_code }}
              <span class="tiny">· {{ new Date(r.created_at).toLocaleString() }}</span>
            </p>
            <p v-if="r.reason_text" class="tiny">{{ r.reason_text }}</p>
            <p class="tiny">
              目标：{{ r.target_type }} ·
              <span class="mono">{{ r.target_id }}</span>
            </p>
            <p v-if="targets[`${r.target_type}:${r.target_id}`]?.title" class="tiny">
              主题：{{ targets[`${r.target_type}:${r.target_id}`].title }}
            </p>
            <p v-else-if="targets[`${r.target_type}:${r.target_id}`]?.thread_id" class="tiny">
              楼层：#{{ targets[`${r.target_type}:${r.target_id}`].floor }} · 主题
              <RouterLink :to="`/t/${targets[`${r.target_type}:${r.target_id}`].thread_id}`">打开</RouterLink>
            </p>
          </div>

          <div class="ops">
            <template v-if="r.status === 'open'">
              <button v-if="r.target_type === 'thread'" @click="hideThread(r)">下架主题</button>
              <button v-if="r.target_type === 'thread'" @click="lockThread(r)">锁主题</button>
              <button v-if="r.target_type === 'post'" @click="hidePost(r)">隐藏楼层</button>
              <button class="ghost" @click="rejectReport(r)">驳回</button>
            </template>
            <template v-else>
              <button class="ghost" @click="setReportStatus(r, 'open', 'reopen')">重开</button>
            </template>
          </div>
        </li>
      </ul>
      <p v-else class="state">暂无举报。</p>
    </section>
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
.filters button {
  border: 1px solid var(--border);
  background: var(--surface-2);
  border-radius: 8px;
  padding: 7px 12px;
  cursor: pointer;
}
.tabs {
  display: flex;
  gap: 10px;
  margin: 12px 0;
}
.tab {
  border: 1px solid var(--border);
  background: var(--surface-2);
  border-radius: 999px;
  padding: 7px 14px;
  cursor: pointer;
  font: inherit;
  color: var(--fg-muted);
}
.tab--active {
  background: var(--accent);
  color: var(--accent-fg);
  border-color: color-mix(in srgb, var(--accent) 35%, var(--border));
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
  flex-wrap: wrap;
}
.ops button {
  border: 1px solid var(--border);
  background: var(--surface-2);
  border-radius: 8px;
  padding: 6px 10px;
  cursor: pointer;
}
.ops .ghost {
  color: var(--fg-muted);
}
.ops .danger {
  color: #a33f2f;
}
.rep .mono {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;
}
.state.err {
  color: var(--danger);
}
</style>

