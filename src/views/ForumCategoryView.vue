<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { useAuthContext } from '../composables/useAuthContext'
import { getSupabaseClient } from '../lib/supabase'
import type { ForumCategory, ForumThread } from '../lib/forumApi'
import { getForumCategoryBySlug, listThreadsByCategory } from '../lib/forumApi'

const supabase = getSupabaseClient()
const route = useRoute()
const { userId } = useAuthContext()

const slug = computed(() => String(route.params.categorySlug || ''))

const loading = ref(false)
const err = ref('')
const category = ref<ForumCategory | null>(null)
const threads = ref<ForumThread[]>([])

const canPost = computed(() => !!userId.value && !!category.value && !category.value.is_locked)

async function load() {
  if (!supabase) return
  loading.value = true
  err.value = ''
  category.value = null
  threads.value = []

  const { data: cat, error: cErr } = await getForumCategoryBySlug(supabase, slug.value)
  if (cErr) {
    loading.value = false
    err.value = cErr.message
    return
  }
  if (!cat) {
    loading.value = false
    err.value = '找不到这个版块。'
    return
  }
  category.value = cat as ForumCategory

  const { data: list, error: lErr } = await listThreadsByCategory(supabase, cat.id, 60)
  loading.value = false
  if (lErr) {
    err.value = lErr.message
    return
  }
  threads.value = (list ?? []) as ForumThread[]
}

watch(slug, () => void load(), { immediate: true })
onMounted(() => void load())
</script>

<template>
  <div class="crumb">
    <RouterLink to="/forum">论坛</RouterLink>
    <span class="sep">/</span>
    <span v-if="category">{{ category.title }}</span>
    <span v-else>版块</span>
  </div>

  <div class="page-head">
    <div class="head-left">
      <h1>{{ category?.title || '版块' }}</h1>
      <p class="sub">{{ category?.description || '—' }}</p>
    </div>
    <div class="head-right">
      <RouterLink v-if="canPost" class="btn" :to="`/forum/new?category=${encodeURIComponent(category!.slug)}`">
        发主题
      </RouterLink>
      <RouterLink v-else-if="!userId" class="btn" :to="`/me?redirect=${encodeURIComponent(route.fullPath)}`">
        登录后发帖
      </RouterLink>
      <span v-else class="btn btn--disabled" aria-disabled="true">只读版块</span>
    </div>
  </div>

  <p v-if="!supabase" class="warn">未配置 Supabase 环境变量，论坛不可用。</p>
  <p v-else-if="loading" class="state">加载中...</p>
  <p v-else-if="err" class="state err">{{ err }}</p>
  <ul v-else class="threads">
    <li v-for="t in threads" :key="t.id" class="thread">
      <RouterLink class="thread-link" :to="`/t/${t.id}`">
        <div class="row">
          <span class="title">{{ t.title }}</span>
          <span v-if="t.status === 'locked'" class="badge">锁</span>
          <span v-else-if="t.status === 'hidden'" class="badge badge--warn">隐藏</span>
        </div>
        <p class="meta">回复 {{ t.reply_count }} · {{ new Date(t.updated_at).toLocaleString() }}</p>
      </RouterLink>
    </li>
    <li v-if="!threads.length" class="empty">还没有主题～你来开个头？</li>
  </ul>
</template>

<style scoped>
.crumb {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.85rem;
  color: var(--fg-soft);
  margin-bottom: 12px;
}
.crumb a {
  color: var(--accent);
  text-decoration: none;
}
.sep {
  opacity: 0.7;
}
.page-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 14px;
}
h1 {
  margin: 0 0 6px;
}
.sub {
  margin: 0;
  color: var(--fg-muted);
}
.btn {
  border: 1px solid var(--border);
  background: var(--accent);
  color: var(--accent-fg);
  text-decoration: none;
  border-radius: 999px;
  padding: 9px 14px;
  font-weight: 700;
  font-size: 0.88rem;
  white-space: nowrap;
}
.btn--disabled {
  background: var(--surface-2);
  color: var(--fg-soft);
}
.warn {
  color: var(--danger);
}
.state.err {
  color: var(--danger);
}
.threads {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 10px;
}
.thread {
  border: 1px solid var(--border);
  border-radius: 14px;
  background: var(--surface);
  box-shadow: var(--shadow);
}
.thread-link {
  display: block;
  padding: 12px 14px;
  text-decoration: none;
  color: inherit;
}
.row {
  display: flex;
  align-items: center;
  gap: 10px;
}
.title {
  font-weight: 800;
  flex: 1;
  min-width: 0;
}
.meta {
  margin: 6px 0 0;
  font-size: 0.82rem;
  color: var(--fg-soft);
}
.badge {
  font-size: 0.78rem;
  padding: 3px 10px;
  border-radius: 999px;
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--fg-soft);
}
.badge--warn {
  color: var(--danger);
}
.empty {
  padding: 14px;
  border: 1px dashed var(--border);
  border-radius: 14px;
  color: var(--fg-muted);
}
</style>

