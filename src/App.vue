<script setup lang="ts">
import { computed, onMounted, onUnmounted, provide, ref } from 'vue'
import { RouterLink } from 'vue-router'
import type { Session } from '@supabase/supabase-js'
import AppHeader from './components/AppHeader.vue'
import UploadDrawer from './components/UploadDrawer.vue'
import { authContextKey } from './composables/useAuthContext'
import { siteDataKey, siteErrorKey, siteLoadingKey } from './composables/useSiteData'
import { getSupabaseClient } from './lib/supabase'
import type { CharacterPack, ContentItem, PackBranch, PluginListing, Profile, SiteData, SoftwareModule } from './types'

type UploadPayload =
  | {
      kind: 'plugin'
      name: string
      author: string
      link: string
      intro: string
      previewImage: string
      tags: string[]
      minVersion: string
    }
  | {
      kind: 'pack'
      name: string
      author: string
      link: string
      intro: string
      previewImage: string
      sections: CharacterPack['sections']
    }
  | {
      kind: 'pack-branch'
      name: string
      author: string
      link: string
      intro: string
      previewImage: string
      branchKind: PackBranch['kind']
      content: string
    }
  | {
      kind: 'module'
      name: string
      author: string
      link: string
      intro: string
      previewImage: string
      moduleKind: string
      tags: string[]
    }

const BLOCKED_WORDS = ['血腥', '肢解', '虐杀', '强奸', '乱伦', '幼女', '幼男', '未成年色情', 'nude', 'rape']

const siteData = ref<SiteData | null>(null)
const loading = ref(true)
const error = ref('')
const uploadOpen = ref(false)
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

provide(siteDataKey, siteData)
provide(siteLoadingKey, loading)
provide(siteErrorKey, error)
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

const LS_KEYS = {
  plugins: 'oclive.local.plugins',
  packs: 'oclive.local.packs',
  modules: 'oclive.local.modules',
  branches: 'oclive.local.packBranches',
}

let authSub: { unsubscribe: () => void } | null = null

const adminEmails = computed(() => {
  const v = (import.meta.env.VITE_ADMIN_EMAILS || '').trim()
  if (!v) return [] as string[]
  return v
    .split(',')
    .map((x) => x.trim().toLowerCase())
    .filter(Boolean)
})

function slugify(input: string) {
  const s = input
    .toLowerCase()
    .replace(/[^a-z0-9\u4e00-\u9fa5]+/g, '-')
    .replace(/(^-+|-+$)/g, '')
  return s || `item-${Date.now()}`
}

function readLocalArray<T>(key: string): T[] {
  try {
    const raw = localStorage.getItem(key)
    if (!raw) return []
    const parsed = JSON.parse(raw) as unknown
    return Array.isArray(parsed) ? (parsed as T[]) : []
  } catch {
    return []
  }
}

function writeLocalArray<T>(key: string, values: T[]) {
  localStorage.setItem(key, JSON.stringify(values))
}

function showToast(message: string) {
  toast.value = message
  window.setTimeout(() => {
    if (toast.value === message) toast.value = ''
  }, 2600)
}

function violatesContentPolicy(payload: UploadPayload) {
  const text =
    payload.kind === 'pack'
      ? [
          payload.name,
          payload.intro,
          payload.author,
          payload.sections.scene,
          payload.sections.persona,
          payload.sections.identity,
          payload.sections.world,
          payload.sections.schedule,
        ].join(' ')
      : [payload.name, payload.intro, payload.author].join(' ')
  const lower = text.toLowerCase()
  return BLOCKED_WORDS.some((w) => lower.includes(w.toLowerCase()))
}

function itemToPack(item: ContentItem): CharacterPack {
  const m = item.metadata || {}
  return {
    id: item.id,
    name: item.title,
    intro: item.description,
    preview_image: (m.preview_image as string) || '',
    link: item.download_url,
    author: item.author_name || 'unknown',
    sections: {
      scene: (m.scene as string) || '',
      persona: (m.persona as string) || '',
      identity: (m.identity as string) || '',
      world: (m.world as string) || '',
      schedule: (m.schedule as string) || '',
    },
  }
}

function itemToPlugin(item: ContentItem): PluginListing {
  const m = item.metadata || {}
  return {
    id: item.id,
    name: item.title,
    description: item.description,
    repo_url: item.download_url,
    min_oclive_version: (m.min_oclive_version as string) || '0.2.0',
    tags: item.tags ?? [],
    author: item.author_name || 'unknown',
  }
}

function itemToModule(item: ContentItem): SoftwareModule {
  const m = item.metadata || {}
  return {
    id: item.id,
    name: item.title,
    intro: item.description,
    preview_image: (m.preview_image as string) || '',
    link: item.download_url,
    author: item.author_name || 'unknown',
    kind: (m.kind as string) || 'custom',
    tags: item.tags ?? [],
  }
}

function itemToBranch(item: ContentItem): PackBranch {
  const m = item.metadata || {}
  const kind = (m.kind as PackBranch['kind']) || 'scene'
  return {
    id: item.id,
    name: item.title,
    kind,
    intro: item.description,
    content: (m.content as string) || '',
    preview_image: (m.preview_image as string) || '',
    link: item.download_url,
    author: item.author_name || 'unknown',
  }
}

async function fetchPublishedContent() {
  if (!supabase) return [] as ContentItem[]
  const { data, error } = await supabase
    .from('content_items')
    .select(
      'id,type,title,description,tags,author_id,status,download_url,version,metadata,download_count,created_at,updated_at,last_published_at,profiles(username)'
    )
    .eq('status', 'published')
    .order('last_published_at', { ascending: false })
  if (error) {
    showToast(`云端读取失败：${error.message}`)
    return []
  }
  return (data ?? []).map((x) => {
    const row = x as ContentItem & { profiles?: { username?: string } | null }
    return { ...row, author_name: row.profiles?.username || '' }
  })
}

/** 静态站点数据与 Supabase 列表互不依赖，并行请求以缩短首屏 */
async function loadStaticSiteData(baseUrl: string): Promise<SiteData> {
  let r = await fetch(`${baseUrl}data/site.json`)
  if (r.ok) {
    const base = (await r.json()) as SiteData
    return {
      ...base,
      pack_branches: base.pack_branches ?? [],
    }
  }
  r = await fetch(`${baseUrl}data/plugins.json`)
  if (!r.ok) throw new Error(`无法加载 site.json 或 plugins.json（HTTP ${r.status}）`)
  const j = (await r.json()) as { plugins: SiteData['plugins'] }
  return {
    character_packs: [],
    plugins: j.plugins ?? [],
    modules: [],
    pack_branches: [],
  }
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const baseUrl = import.meta.env.BASE_URL
    const [baseData, cloudItems] = await Promise.all([loadStaticSiteData(baseUrl), fetchPublishedContent()])
    siteData.value = baseData
    if (!siteData.value) return
    const cloudPacks = cloudItems.filter((x) => x.type === 'character').map(itemToPack)
    const cloudPlugins = cloudItems.filter((x) => x.type === 'plugin').map(itemToPlugin)
    const cloudModules = cloudItems.filter((x) => x.type === 'module').map(itemToModule)
    const cloudBranches = cloudItems.filter((x) => x.type === 'branch').map(itemToBranch)

    siteData.value.character_packs = [
      ...cloudPacks,
      ...readLocalArray<CharacterPack>(LS_KEYS.packs),
      ...siteData.value.character_packs,
    ]
    siteData.value.plugins = [...cloudPlugins, ...readLocalArray<PluginListing>(LS_KEYS.plugins), ...siteData.value.plugins]
    siteData.value.modules = [...cloudModules, ...readLocalArray<SoftwareModule>(LS_KEYS.modules), ...siteData.value.modules]
    siteData.value.pack_branches = [
      ...cloudBranches,
      ...readLocalArray<PackBranch>(LS_KEYS.branches),
      ...siteData.value.pack_branches,
    ]

    siteData.value.character_packs = siteData.value.character_packs.map((p) => ({
      ...p,
      sections: {
        scene: p.sections?.scene ?? '',
        persona: p.sections?.persona ?? '',
        identity: p.sections?.identity ?? '',
        world: p.sections?.world ?? '',
        schedule: p.sections?.schedule ?? '',
      },
    }))
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e)
  } finally {
    loading.value = false
  }
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
  showToast('登录邮件已发送，请到邮箱点击链接。')
}

async function signOut() {
  if (!supabase) return
  authBusy.value = true
  await supabase.auth.signOut()
  authBusy.value = false
  showToast('已退出登录。')
}

async function submitToCloud(payload: UploadPayload) {
  if (!supabase || !userId.value) return false
  if (violatesContentPolicy(payload)) {
    showToast('命中禁用词（血腥/暴力/色情），请修改后再发布。')
    return true
  }

  const common = {
    title: payload.name,
    description: payload.intro,
    author_id: userId.value,
    status: 'published' as const,
    download_url: payload.link,
  }

  let row: Omit<ContentItem, 'id' | 'author_name' | 'created_at' | 'updated_at' | 'download_count' | 'last_published_at'>
  if (payload.kind === 'pack') {
    row = {
      ...common,
      type: 'character',
      tags: ['character'],
      version: 'v1.0.0',
      metadata: {
        preview_image: payload.previewImage,
        scene: payload.sections.scene,
        persona: payload.sections.persona,
        identity: payload.sections.identity,
        world: payload.sections.world,
        schedule: payload.sections.schedule,
      },
    }
  } else if (payload.kind === 'plugin') {
    row = {
      ...common,
      type: 'plugin',
      tags: payload.tags,
      version: payload.minVersion || 'v1.0.0',
      metadata: { min_oclive_version: payload.minVersion || '0.2.0', preview_image: payload.previewImage },
    }
  } else if (payload.kind === 'module') {
    row = {
      ...common,
      type: 'module',
      tags: payload.tags,
      version: 'v1.0.0',
      metadata: { kind: payload.moduleKind || 'custom', preview_image: payload.previewImage },
    }
  } else {
    row = {
      ...common,
      type: 'branch',
      tags: [payload.branchKind],
      version: 'v1.0.0',
      metadata: { kind: payload.branchKind, content: payload.content, preview_image: payload.previewImage },
    }
  }

  const { error: e } = await supabase.from('content_items').insert(row)
  if (e) {
    showToast(`云端提交失败：${e.message}`)
    return true
  }
  showToast('内容已提交到云端。')
  await load()
  return true
}

function saveLocally(payload: UploadPayload) {
  if (!siteData.value) return
  if (payload.kind === 'plugin') {
    const item: PluginListing = {
      id: `plugin-${slugify(payload.name)}-${Date.now().toString(36)}`,
      name: payload.name,
      description: payload.intro,
      repo_url: payload.link,
      min_oclive_version: payload.minVersion || '0.2.0',
      tags: payload.tags,
      author: payload.author,
    }
    siteData.value.plugins.unshift(item)
    writeLocalArray(LS_KEYS.plugins, siteData.value.plugins.filter((x) => x.id.startsWith('plugin-')))
    return
  }
  if (payload.kind === 'pack') {
    const item: CharacterPack = {
      id: `pack-${slugify(payload.name)}-${Date.now().toString(36)}`,
      name: payload.name,
      intro: payload.intro,
      preview_image: payload.previewImage,
      link: payload.link,
      author: payload.author,
      sections: payload.sections,
    }
    siteData.value.character_packs.unshift(item)
    writeLocalArray(LS_KEYS.packs, siteData.value.character_packs.filter((x) => x.id.startsWith('pack-')))
    return
  }
  if (payload.kind === 'pack-branch') {
    const item: PackBranch = {
      id: `branch-${payload.branchKind}-${slugify(payload.name)}-${Date.now().toString(36)}`,
      kind: payload.branchKind,
      name: payload.name,
      intro: payload.intro,
      content: payload.content,
      preview_image: payload.previewImage,
      link: payload.link,
      author: payload.author,
    }
    siteData.value.pack_branches.unshift(item)
    writeLocalArray(LS_KEYS.branches, siteData.value.pack_branches.filter((x) => x.id.startsWith('branch-')))
    return
  }
  const item: SoftwareModule = {
    id: `module-${slugify(payload.name)}-${Date.now().toString(36)}`,
    name: payload.name,
    intro: payload.intro,
    preview_image: payload.previewImage,
    link: payload.link,
    author: payload.author,
    kind: payload.moduleKind || 'custom',
    tags: payload.tags,
  }
  siteData.value.modules.unshift(item)
  writeLocalArray(LS_KEYS.modules, siteData.value.modules.filter((x) => x.id.startsWith('module-')))
}

async function onSubmit(payload: UploadPayload) {
  if (!siteData.value) return
  const cloudHandled = await submitToCloud(payload)
  if (cloudHandled) return
  saveLocally(payload)
  showToast('未连接云端，已保存到本地浏览器。')
}

onMounted(() => {
  void load()
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
      @open-upload="uploadOpen = true"
    />
    <UploadDrawer
      :open="uploadOpen"
      :auth-configured="authConfigured"
      :user-email="userEmail"
      :auth-busy="authBusy"
      @close="uploadOpen = false"
      @submit="onSubmit"
      @login="signInWithEmail"
      @logout="signOut"
    />

    <main id="main" class="main">
      <p v-if="toast" class="toast" role="status">{{ toast }}</p>
      <router-view />
    </main>

    <footer class="foot">
      <p>
        <RouterLink to="/versions">软件版本与下载</RouterLink>
        ·
        文档：
        <a
          href="https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/roadmap/PLUGIN_WEB_SECTION.md"
          target="_blank"
          rel="noopener"
          >PLUGIN_WEB_SECTION</a
        >
      </p>
      <p class="muted">OCLive 市场 · 静态站点</p>
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
