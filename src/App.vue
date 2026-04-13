<script setup lang="ts">
import { computed, onMounted, onUnmounted, provide, ref } from 'vue'
import { RouterLink } from 'vue-router'
import type { Session } from '@supabase/supabase-js'
import AppHeader from './components/AppHeader.vue'
import { mumu } from './content/mumuCopy'
import { authContextKey } from './composables/useAuthContext'
import { getSupabaseClient } from './lib/supabase'
import type { Profile } from './types'

const toast = ref('')

const authBusy = ref(false)
const authConfigured = ref(false)
const userId = ref('')
const userEmail = ref('')
const username = ref('')
const avatarUrl = ref('')
const isAdmin = ref(false)
const profile = ref<Profile | null>(null)

const supabase = getSupabaseClient()
authConfigured.value = !!supabase

provide(authContextKey, {
  authConfigured,
  authBusy,
  userId,
  userEmail,
  username,
  avatarUrl,
  isAdmin,
  signInWithEmail,
  signOut,
  refreshProfile,
})

const adminEmails = computed(() => {
  const v = (import.meta.env.VITE_ADMIN_EMAILS || '').trim()
  if (!v) return [] as string[]
  return v
    .split(',')
    .map((x) => x.trim().toLowerCase())
    .filter(Boolean)
})

function showToast(message: string) {
  toast.value = message
  window.setTimeout(() => {
    if (toast.value === message) toast.value = ''
  }, 2600)
}

async function ensureProfile(session: Session | null) {
  if (!supabase || !session) return
  const inferred = session.user.email?.split('@')[0] || `user_${session.user.id.slice(0, 8)}`
  await supabase.from('profiles').upsert(
    {
      id: session.user.id,
      username: inferred,
      avatar_url: '',
    },
    { onConflict: 'id', ignoreDuplicates: true }
  )
}

async function refreshProfile() {
  if (!supabase || !userId.value) {
    profile.value = null
    username.value = ''
    avatarUrl.value = ''
    isAdmin.value = false
    return
  }
  const { data, error: e } = await supabase
    .from('profiles')
    .select('id,username,avatar_url,is_admin,created_at,updated_at')
    .eq('id', userId.value)
    .single()
  if (e || !data) return
  profile.value = data as Profile
  username.value = profile.value.username || ''
  avatarUrl.value = profile.value.avatar_url || ''
  const mailAdmin = userEmail.value ? adminEmails.value.includes(userEmail.value.toLowerCase()) : false
  isAdmin.value = !!profile.value.is_admin || mailAdmin
}

let authSub: { unsubscribe: () => void } | null = null

async function setupAuth() {
  if (!supabase) return
  const { error: initError } = await supabase.auth.initialize()
  if (initError) {
    showToast(`登录链接无效或已过期：${initError.message}`)
  }
  const { data } = await supabase.auth.getSession()
  await setSession(data.session)
  const sub = supabase.auth.onAuthStateChange(async (_event, session) => {
    await setSession(session)
  })
  authSub = sub.data.subscription
}

async function setSession(session: Session | null) {
  userId.value = session?.user?.id ?? ''
  userEmail.value = session?.user?.email ?? ''
  if (!session) {
    profile.value = null
    username.value = ''
    avatarUrl.value = ''
    isAdmin.value = false
    return
  }
  await ensureProfile(session)
  await refreshProfile()
}

async function signInWithEmail(email: string) {
  if (!supabase) {
    showToast('未配置 Supabase。')
    return
  }
  authBusy.value = true
  const redirect = `${window.location.origin}${import.meta.env.BASE_URL}`
  const { error: e } = await supabase.auth.signInWithOtp({ email, options: { emailRedirectTo: redirect } })
  authBusy.value = false
  if (e) {
    showToast(`发送失败：${e.message}`)
    return
  }
  showToast(mumu.toastEmailSent)
}

async function signOut() {
  if (!supabase) return
  authBusy.value = true
  await supabase.auth.signOut()
  authBusy.value = false
  showToast(mumu.toastSignOut)
}

onMounted(() => {
  void setupAuth()
})

onUnmounted(() => {
  authSub?.unsubscribe()
})
</script>

<template>
  <div class="page">
    <a class="skip" href="#main">跳到主要内容</a>
    <AppHeader
      :is-admin="isAdmin"
      :is-authed="!!userId"
      :avatar-url="avatarUrl"
      :username="username"
    />
    <main id="main" class="main">
      <p v-if="toast" class="toast" role="status">{{ toast }}</p>
      <router-view />
    </main>

    <footer class="foot">
      <p>
        <RouterLink to="/versions">软件版本与下载</RouterLink>
        ·
        <RouterLink to="/announcements">公告</RouterLink>
        ·
        文档：
        <a
          href="https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/roadmap/PLUGIN_WEB_SECTION.md"
          target="_blank"
          rel="noopener"
          >PLUGIN_WEB_SECTION</a
        >
      </p>
      <p class="muted">沐沐和 Oclive 祝你用得开心～有问题先看文档，再来社区转转。</p>
    </footer>
  </div>
</template>

<style scoped>
.page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  color: var(--fg);
  background: var(--bg);
  font-family: system-ui, -apple-system, 'Segoe UI', sans-serif;
  line-height: 1.5;
}

.skip {
  position: absolute;
  left: -9999px;
  top: 0;
  padding: 8px 12px;
  background: var(--accent);
  color: var(--accent-fg);
  z-index: 300;
}
.skip:focus {
  left: 12px;
  top: 12px;
}

.main {
  flex: 1;
  width: 100%;
  max-width: 1120px;
  margin: 0 auto;
  padding: 20px 18px 48px;
}

.toast {
  margin: 0 0 14px;
  padding: 10px 12px;
  border-radius: 10px;
  border: 1px solid var(--accent-soft);
  background: color-mix(in srgb, var(--accent) 10%, var(--surface));
  color: var(--fg);
  font-size: 0.9rem;
}

.foot {
  padding: 20px 18px 32px;
  border-top: 1px solid var(--border);
  font-size: 0.85rem;
  color: var(--fg-soft);
  text-align: center;
}
.foot p {
  margin: 0 0 6px;
}
.foot a {
  color: var(--accent);
}
.foot .muted {
  color: var(--fg-soft);
}
</style>

<style>
:root {
  --fg: #3a342c;
  --fg-muted: #5c564c;
  --fg-soft: #8a8275;
  --bg: #f2ebe3;
  --surface: #faf6f0;
  --surface-2: #f0e8de;
  --border: #e0d6c8;
  --accent: #7a6b58;
  --accent-soft: #9c8f7a;
  --accent-fg: #faf8f4;
  --danger: #a85c4a;
  --shadow: 0 1px 2px rgba(58, 52, 42, 0.06);
  --code-bg: #e8dfd4;
}

@media (prefers-color-scheme: dark) {
  :root {
    --fg: #ebe4d9;
    --fg-muted: #c4bbae;
    --fg-soft: #9a9185;
    --bg: #1e1c18;
    --surface: #26231f;
    --surface-2: #2e2a25;
    --border: #3d3830;
    --accent: #b5a892;
    --accent-soft: #c9bdab;
    --accent-fg: #1e1c18;
    --danger: #d4a090;
    --shadow: 0 1px 3px rgba(0, 0, 0, 0.35);
    --code-bg: #3a342c;
  }
}
</style>
