<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import AvatarImg from '../components/AvatarImg.vue'
import { useAuthContext } from '../composables/useAuthContext'
import { getSupabaseClient } from '../lib/supabase'
import type { ForumCategory, ForumPost, ForumProfileLite, ForumThread } from '../lib/forumApi'
import { createReply, createReport, getProfileLite, getThread, listThreadPosts } from '../lib/forumApi'

const supabase = getSupabaseClient()
const route = useRoute()
const { userId, isAdmin } = useAuthContext()

const threadId = computed(() => String(route.params.threadId || ''))

const loading = ref(false)
const err = ref('')
const info = ref('')

const thread = ref<ForumThread | null>(null)
const category = ref<ForumCategory | null>(null)
const posts = ref<ForumPost[]>([])
const author = ref<ForumProfileLite | null>(null)
const postAuthors = ref<Record<string, ForumProfileLite>>({})

const replyText = ref('')
const replying = ref(false)

const threadLocked = computed(() => thread.value?.status === 'locked' || category.value?.is_locked)
const canReply = computed(() => !!supabase && !!userId.value && !threadLocked.value)

function toast(msg: string) {
  info.value = msg
  window.setTimeout(() => {
    if (info.value === msg) info.value = ''
  }, 2400)
}

async function load() {
  if (!supabase) return
  loading.value = true
  err.value = ''
  thread.value = null
  category.value = null
  posts.value = []
  author.value = null
  postAuthors.value = {}

  const { data: t, error: tErr } = await getThread(supabase, threadId.value)
  if (tErr) {
    loading.value = false
    err.value = tErr.message
    return
  }
  if (!t) {
    loading.value = false
    err.value = '找不到这个主题。'
    return
  }
  thread.value = t as ForumThread

  const { data: authorRow } = await getProfileLite(supabase, thread.value.author_id)
  author.value = (authorRow ?? null) as ForumProfileLite | null

  // category: need slug? we only have id; simplest: fetch via categories table by id
  const { data: catRow, error: cErr } = await supabase
    .from('forum_categories')
    .select('*')
    .eq('id', thread.value.category_id)
    .maybeSingle()
  if (cErr) {
    loading.value = false
    err.value = cErr.message
    return
  }
  category.value = (catRow ?? null) as ForumCategory | null

  const { data: p, error: pErr } = await listThreadPosts(supabase, threadId.value, 240)
  loading.value = false
  if (pErr) {
    err.value = pErr.message
    return
  }
  posts.value = (p ?? []) as ForumPost[]

  const ids = Array.from(new Set(posts.value.map((x) => x.author_id).filter(Boolean)))
  if (ids.length) {
    const { data: profs } = await supabase
      .from('profiles')
      .select('id,username,avatar_url,donation_url,donation_qr_url')
      .in('id', ids)
    const map: Record<string, ForumProfileLite> = {}
    for (const r of (profs ?? []) as ForumProfileLite[]) map[r.id] = r
    postAuthors.value = map
  }
}

async function doReply() {
  if (!supabase || !userId.value || !thread.value) return
  const text = replyText.value.trim()
  if (!text) return
  if (threadLocked.value) {
    toast('这个主题已锁，不能回帖。')
    return
  }
  replying.value = true
  const { error } = await createReply({ supabase, threadId: thread.value.id, authorId: userId.value, content: text })
  replying.value = false
  if (error) {
    toast(error.message)
    return
  }
  replyText.value = ''
  toast('已回帖。')
  await load()
}

async function report(targetType: 'thread' | 'post', targetId: string) {
  if (!supabase || !userId.value) {
    toast('先登录再举报～')
    return
  }
  const reason = window.prompt('举报原因代码（spam/abuse/illegal/other）', 'spam')?.trim() || ''
  const reasonCode = (['spam', 'abuse', 'illegal', 'other'] as const).includes(reason as any) ? (reason as any) : null
  if (!reasonCode) {
    toast('原因代码不对，取消了。')
    return
  }
  const reasonText = window.prompt('补充说明（可选）', '') ?? ''
  const { error } = await createReport({
    supabase,
    targetType,
    targetId,
    reporterId: userId.value,
    reasonCode,
    reasonText,
  })
  if (error) {
    toast(error.message)
    return
  }
  toast('已举报，感谢你帮忙清理环境。')
}

watch(threadId, () => void load(), { immediate: true })
onMounted(() => void load())
</script>

<template>
  <div class="crumb">
    <RouterLink to="/forum">论坛</RouterLink>
    <span class="sep">/</span>
    <RouterLink v-if="category" :to="`/forum/${category.slug}`">{{ category.title }}</RouterLink>
    <span v-else>主题</span>
  </div>

  <p v-if="info" class="info">{{ info }}</p>
  <p v-if="!supabase" class="warn">未配置 Supabase 环境变量，论坛不可用。</p>
  <p v-else-if="loading" class="state">加载中...</p>
  <p v-else-if="err" class="state err">{{ err }}</p>

  <template v-else-if="thread">
    <header class="thread-head">
      <div class="head-top">
        <h1 class="title">{{ thread.title }}</h1>
        <div class="head-ops">
          <button class="ghost" @click="report('thread', thread.id)">举报主题</button>
          <span v-if="thread.status === 'locked'" class="badge">已锁</span>
          <span v-else-if="thread.status === 'hidden'" class="badge badge--warn">隐藏</span>
        </div>
      </div>
      <p class="meta">
        回复 {{ thread.reply_count }} · 更新 {{ new Date(thread.updated_at).toLocaleString() }}
        <span v-if="threadLocked" class="meta-lock">· 当前只读</span>
      </p>

      <section v-if="author && (author.donation_url || author.donation_qr_url)" class="donate">
        <div class="donate-left">
          <p class="donate-title">支持作者</p>
          <p class="donate-sub">如果这个帖子帮到你了，可以请作者喝杯奶茶～</p>
        </div>
        <div class="donate-right">
          <a v-if="author.donation_url" class="donate-link" :href="author.donation_url" target="_blank" rel="noopener">
            打赏链接
          </a>
          <a
            v-if="author.donation_qr_url"
            class="donate-link"
            :href="author.donation_qr_url"
            target="_blank"
            rel="noopener"
          >
            收款码
          </a>
        </div>
      </section>
    </header>

    <ol class="posts">
      <li v-for="p in posts" :key="p.id" class="post">
        <div class="post-left">
          <AvatarImg
            v-if="postAuthors[p.author_id]?.avatar_url"
            :stored-url="postAuthors[p.author_id].avatar_url"
            img-class="avatar"
          />
          <div v-else class="avatar avatar--fallback">
            {{ postAuthors[p.author_id]?.username?.slice(0, 1) || 'U' }}
          </div>
        </div>
        <div class="post-main">
          <div class="post-top">
            <p class="who">
              <strong>{{ postAuthors[p.author_id]?.username || p.author_id }}</strong>
              <span class="tiny">#{{ p.floor }} · {{ new Date(p.created_at).toLocaleString() }}</span>
              <span v-if="p.status === 'hidden'" class="badge badge--warn">隐藏</span>
            </p>
            <div class="post-ops">
              <button class="ghost" @click="report('post', p.id)">举报</button>
            </div>
          </div>
          <pre class="content">{{ p.content }}</pre>
        </div>
      </li>
    </ol>

    <section class="reply card">
      <h2 class="h2">回帖</h2>
      <p v-if="!userId" class="hint">
        <RouterLink :to="`/me?redirect=${encodeURIComponent(route.fullPath)}`">登录</RouterLink>
        后就能回帖。
      </p>
      <p v-else-if="threadLocked" class="hint">主题已锁/版块只读，不能回帖。</p>
      <template v-else>
        <textarea v-model="replyText" rows="6" placeholder="说点啥吧～（纯文本，支持换行）" />
        <div class="ops">
          <button :disabled="replying || !replyText.trim() || !canReply" @click="doReply">
            {{ replying ? '正在发送…' : '发送回帖' }}
          </button>
          <span v-if="isAdmin" class="admin-hint">管理员处理举报请到「管理」页。</span>
        </div>
      </template>
    </section>
  </template>
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
.info {
  margin: 0 0 10px;
  color: var(--accent);
}
.warn {
  color: var(--danger);
}
.state.err {
  color: var(--danger);
}
.thread-head {
  margin-bottom: 14px;
}
.head-top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 10px;
}
.title {
  margin: 0;
  letter-spacing: -0.02em;
}
.meta {
  margin: 6px 0 0;
  color: var(--fg-muted);
}
.meta-lock {
  color: var(--danger);
}
.head-ops {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
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
.donate {
  margin-top: 12px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background: color-mix(in srgb, var(--accent) 7%, var(--surface));
  padding: 12px;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 10px 12px;
}
.donate-title {
  margin: 0 0 2px;
  font-weight: 800;
}
.donate-sub {
  margin: 0;
  color: var(--fg-muted);
  font-size: 0.9rem;
}
.donate-right {
  display: flex;
  gap: 8px;
}
.donate-link {
  border: 1px solid var(--border);
  background: var(--surface);
  border-radius: 999px;
  padding: 8px 12px;
  text-decoration: none;
  color: var(--accent);
  font-weight: 700;
  font-size: 0.88rem;
}
.posts {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 10px;
}
.post {
  display: grid;
  grid-template-columns: 44px 1fr;
  gap: 10px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background: var(--surface);
  box-shadow: var(--shadow);
  padding: 12px;
}
.avatar {
  width: 42px;
  height: 42px;
  border-radius: 999px;
  border: 1px solid var(--border);
  object-fit: cover;
}
.avatar--fallback {
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--surface-2);
  color: var(--fg-soft);
  font-weight: 800;
}
.post-top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 10px;
}
.who {
  margin: 0;
  color: var(--fg-muted);
}
.tiny {
  margin-left: 10px;
  color: var(--fg-soft);
  font-size: 0.82rem;
}
.content {
  margin: 10px 0 0;
  white-space: pre-wrap;
  font-family: inherit;
  color: var(--fg);
  line-height: 1.6;
}
.ghost {
  border: 1px solid var(--border);
  background: var(--surface-2);
  border-radius: 10px;
  padding: 6px 10px;
  cursor: pointer;
  font: inherit;
  font-size: 0.82rem;
  color: var(--fg-muted);
}
.reply.card {
  margin-top: 14px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background: var(--surface);
  padding: 14px;
}
.h2 {
  margin: 0 0 10px;
  font-size: 1.05rem;
}
.hint {
  margin: 0 0 10px;
  color: var(--fg-muted);
}
.reply textarea {
  width: 100%;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: var(--surface-2);
  padding: 10px;
  font: inherit;
  color: inherit;
  resize: vertical;
}
.reply .ops {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  margin-top: 10px;
}
.reply button {
  border: 1px solid var(--border);
  background: var(--accent);
  color: var(--accent-fg);
  border-radius: 999px;
  padding: 9px 16px;
  cursor: pointer;
  font-weight: 800;
}
.reply button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.admin-hint {
  font-size: 0.82rem;
  color: var(--fg-soft);
}
</style>

