<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const props = defineProps<{
  isAdmin: boolean
  isAuthed: boolean
  avatarUrl: string
  username: string
}>()
const emit = defineEmits<{ openUpload: [] }>()

const router = useRouter()
const current = useRoute()
const qLocal = ref('')

watch(
  () => current.query.q,
  (q) => {
    qLocal.value = typeof q === 'string' ? q : ''
  },
  { immediate: true }
)

const nav = [
  { to: '/', label: '主页' },
  { to: '/packs', label: '角色包' },
  { to: '/plugins', label: '插件' },
  { to: '/modules', label: '模块' },
  { to: '/me', label: '个人设置' },
  { to: '/manage', label: '我的上传' },
]

function goSearch() {
  const q = qLocal.value.trim()
  if (!q) {
    router.push({ name: 'search' })
    return
  }
  router.push({ name: 'search', query: { q } })
}

const onSearchPage = computed(() => current.name === 'search')
</script>

<template>
  <header class="header">
    <div class="header-inner">
      <div class="left">
        <RouterLink to="/" class="brand">
          <span class="logo" aria-hidden="true">◇</span>
          <span class="brand-text">OCLive 市场</span>
        </RouterLink>
        <nav class="nav" aria-label="主导航">
          <RouterLink
            v-for="n in nav"
            :key="n.to"
            :to="n.to"
            class="nav-link"
            active-class="nav-link--active"
          >
            {{ n.label }}
          </RouterLink>
        </nav>
      </div>

      <div class="search-wrap">
        <label class="sr-only" for="global-search">全站搜索</label>
        <input
          id="global-search"
          v-model="qLocal"
          type="search"
          class="search"
          placeholder="搜索角色包、插件、模块…"
          autocomplete="off"
          @keydown.enter.prevent="goSearch"
        />
        <button type="button" class="search-btn" @click="goSearch">
          {{ onSearchPage ? '更新' : '搜索' }}
        </button>
      </div>

      <div class="right">
        <RouterLink v-if="props.isAdmin" to="/admin" class="admin-link">管理</RouterLink>
        <RouterLink v-if="props.isAuthed" to="/me" class="avatar-link" title="个人设置">
          <img v-if="props.avatarUrl" :src="props.avatarUrl" alt="avatar" class="avatar" />
          <span v-else class="avatar-fallback">{{ props.username?.slice(0, 1) || 'U' }}</span>
        </RouterLink>
        <button type="button" class="upload-btn" @click="emit('openUpload')">上传</button>
      </div>
    </div>
  </header>
</template>

<style scoped>
.header {
  position: sticky;
  top: 0;
  z-index: 60;
  border-bottom: 1px solid var(--border);
  background: color-mix(in srgb, var(--surface) 92%, transparent);
  backdrop-filter: blur(12px);
}

.header-inner {
  max-width: 1120px;
  margin: 0 auto;
  padding: 10px 18px;
  display: grid;
  gap: 12px 14px;
  grid-template-columns: 1fr auto;
  grid-template-areas:
    'brandnav upload'
    'search search';
  align-items: center;
}

@media (min-width: 900px) {
  .header-inner {
    grid-template-columns: auto 1fr auto;
    grid-template-areas: 'brandnav search upload';
  }
}

.left {
  grid-area: brandnav;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px 18px;
}

.brand {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-weight: 700;
  letter-spacing: -0.02em;
  color: var(--fg);
  text-decoration: none;
  font-size: 1.02rem;
}

.logo {
  color: var(--accent);
  font-size: 1.2rem;
  line-height: 1;
}

.nav {
  display: flex;
  flex-wrap: wrap;
  gap: 6px 14px;
  font-size: 0.88rem;
}

.nav-link {
  color: var(--fg-muted);
  text-decoration: none;
  padding: 4px 2px;
  border-radius: 6px;
}

.nav-link:hover {
  color: var(--accent);
}

.nav-link--active {
  color: var(--accent);
  font-weight: 600;
}

.search-wrap {
  grid-area: search;
  display: flex;
  align-items: stretch;
  gap: 8px;
  min-width: 0;
  max-width: 560px;
  width: 100%;
}

@media (min-width: 900px) {
  .search-wrap {
    justify-self: stretch;
    max-width: none;
  }
}

.search {
  flex: 1;
  min-width: 0;
  padding: 9px 12px;
  font-size: 0.95rem;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: var(--surface-2);
  color: var(--fg);
}

.search:focus {
  outline: 2px solid color-mix(in srgb, var(--accent) 35%, transparent);
  outline-offset: 1px;
}

.search-btn {
  flex-shrink: 0;
  padding: 9px 14px;
  font-size: 0.88rem;
  font-weight: 600;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: var(--surface);
  color: var(--fg-muted);
  cursor: pointer;
}

.search-btn:hover {
  border-color: var(--accent-soft);
  color: var(--accent);
}

.right {
  grid-area: upload;
  justify-self: end;
  display: flex;
  align-items: center;
  gap: 8px;
}

.admin-link {
  font-size: 0.82rem;
  text-decoration: none;
  color: var(--fg-muted);
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 7px 12px;
}
.admin-link:hover {
  color: var(--accent);
  border-color: var(--accent-soft);
}

.avatar-link {
  width: 34px;
  height: 34px;
  border-radius: 999px;
  border: 1px solid var(--border);
  overflow: hidden;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: var(--surface-2);
}
.avatar {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.avatar-fallback {
  font-size: 0.78rem;
  font-weight: 700;
  color: var(--fg-soft);
}

.upload-btn {
  padding: 9px 16px;
  font-size: 0.9rem;
  font-weight: 600;
  border: none;
  border-radius: 999px;
  background: var(--accent);
  color: var(--accent-fg);
  cursor: pointer;
  white-space: nowrap;
}

.upload-btn:hover {
  filter: brightness(1.03);
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
