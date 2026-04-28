<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter, useRoute, RouterLink } from 'vue-router'
import { useAuthContext } from '../composables/useAuthContext'
import { getSupabaseClient } from '../lib/supabase'
import type { ForumCategory } from '../lib/forumApi'
import { createThreadWithFirstPost, getForumCategoryBySlug, listForumCategories } from '../lib/forumApi'

const supabase = getSupabaseClient()
const router = useRouter()
const route = useRoute()
const { userId } = useAuthContext()

const qSlug = computed(() => String(route.query.category || ''))

const loading = ref(false)
const err = ref('')
const info = ref('')

const categories = ref<ForumCategory[]>([])
const category = ref<ForumCategory | null>(null)

const title = ref('')
const content = ref('')
const tagsInput = ref('')

const canSubmit = computed(() => !!supabase && !!userId.value && !!category.value && title.value.trim() && content.value.trim())

function toast(msg: string) {
  info.value = msg
  window.setTimeout(() => {
    if (info.value === msg) info.value = ''
  }, 2400)
}

async function loadCategories() {
  if (!supabase) return
  const { data, error } = await listForumCategories(supabase)
  if (error) {
    err.value = error.message
    return
  }
  categories.value = (data ?? []) as ForumCategory[]
}

async function resolveCategory() {
  if (!supabase) return
  category.value = null
  err.value = ''
  if (qSlug.value) {
    const { data, error } = await getForumCategoryBySlug(supabase, qSlug.value)
    if (error) {
      err.value = error.message
      return
    }
    category.value = (data ?? null) as ForumCategory | null
  } else {
    category.value = categories.value[0] ?? null
  }
}

async function submit() {
  if (!supabase) return
  if (!userId.value) {
    await router.push({ name: 'personal', query: { redirect: route.fullPath } })
    return
  }
  if (!category.value) return
  if (category.value.is_locked) {
    toast('这个版块是只读的，换个版块试试～')
    return
  }
  loading.value = true
  err.value = ''
  const tags = tagsInput.value
    .split(',')
    .map((x) => x.trim())
    .filter(Boolean)
    .slice(0, 8)

  const { thread, error } = await createThreadWithFirstPost({
    supabase,
    categoryId: category.value.id,
    authorId: userId.value,
    title: title.value.trim(),
    content: content.value.trim(),
    tags,
  })
  loading.value = false
  if (error || !thread) {
    err.value = error?.message || '提交失败'
    return
  }
  toast('发帖成功～')
  await router.push(`/t/${thread.id}`)
}

watch(qSlug, () => void resolveCategory())
onMounted(async () => {
  await loadCategories()
  await resolveCategory()
})
</script>

<template>
  <div class="crumb">
    <RouterLink to="/forum">论坛</RouterLink>
    <span class="sep">/</span>
    <span>发主题</span>
  </div>

  <div class="page-head">
    <h1>发主题</h1>
    <p class="sub">默认直接发布。别发违法/辱骂/广告，大家就都开心。</p>
  </div>

  <p v-if="info" class="info">{{ info }}</p>
  <p v-if="!supabase" class="warn">未配置 Supabase 环境变量，论坛不可用。</p>
  <p v-else-if="!userId" class="warn">
    你还没登录～
    <RouterLink :to="`/me?redirect=${encodeURIComponent(route.fullPath)}`">去登录</RouterLink>
    再来发帖。
  </p>

  <section v-else class="card">
    <p v-if="err" class="err">{{ err }}</p>

    <label class="field">
      <span>版块</span>
      <select v-model="category" :disabled="!!qSlug">
        <option v-for="c in categories" :key="c.id" :value="c">{{ c.title }}{{ c.is_locked ? '（只读）' : '' }}</option>
      </select>
    </label>

    <label class="field">
      <span>标题</span>
      <input v-model="title" placeholder="一句话说明你想聊啥" maxlength="120" />
    </label>

    <label class="field">
      <span>内容</span>
      <textarea v-model="content" rows="10" placeholder="先做纯文本；想排版就多用换行～" />
    </label>

    <label class="field">
      <span>标签（可选，逗号分隔）</span>
      <input v-model="tagsInput" placeholder="例如：安装,报错,经验" />
    </label>

    <div class="ops">
      <button :disabled="loading || !canSubmit" @click="submit">{{ loading ? '正在提交…' : '发布' }}</button>
      <RouterLink class="ghost" :to="category ? `/forum/${category.slug}` : '/forum'">返回</RouterLink>
    </div>
  </section>
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
  margin-bottom: 16px;
}
.sub {
  margin: 0;
  color: var(--fg-muted);
}
.info {
  margin: 0 0 12px;
  color: var(--accent);
}
.warn {
  color: var(--danger);
}
.card {
  border: 1px solid var(--border);
  border-radius: 14px;
  background: var(--surface);
  padding: 14px;
  max-width: 760px;
}
.err {
  margin: 0 0 10px;
  color: var(--danger);
}
.field {
  display: grid;
  gap: 6px;
  margin-bottom: 12px;
}
.field span {
  font-size: 0.82rem;
  color: var(--fg-soft);
}
input,
textarea,
select {
  border: 1px solid var(--border);
  border-radius: 10px;
  background: var(--surface-2);
  padding: 9px 10px;
  font: inherit;
  color: inherit;
}
textarea {
  resize: vertical;
}
.ops {
  display: flex;
  gap: 10px;
  align-items: center;
}
button {
  border: 1px solid var(--border);
  background: var(--accent);
  color: var(--accent-fg);
  border-radius: 999px;
  padding: 9px 16px;
  cursor: pointer;
  font-weight: 800;
}
button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.ghost {
  color: var(--fg-muted);
  text-decoration: none;
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 9px 14px;
  background: var(--surface-2);
}
</style>

