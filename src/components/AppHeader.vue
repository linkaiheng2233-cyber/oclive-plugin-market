<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'
import { RouterLink } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AvatarImg from './AvatarImg.vue'
import { useMarketCopy } from '../composables/useMarketCopy'
import { getLocalePreference, setLocalePreference, type LocalePreference } from '../i18n'

const props = defineProps<{
  isAdmin: boolean
  isAuthed: boolean
  avatarUrl: string
  username: string
}>()

const { t } = useI18n()
const mumu = useMarketCopy()
const current = useRoute()

const nav = computed(() => [
  { to: '/', label: t('market.nav.home'), exact: true },
  { to: '/browse', label: t('market.nav.browse'), matchPrefix: '/browse' },
  { to: '/forum', label: t('market.nav.forum'), matchPrefix: '/forum' },
  { to: '/docs/creator', label: t('market.nav.docs'), matchPrefix: '/docs/creator' },
  { to: '/announcements', label: t('market.nav.announcements'), matchPrefix: '/announcements' },
  { to: '/submit', label: t('market.nav.submit'), matchPrefix: '/submit' },
  { to: '/versions', label: t('market.nav.versions'), matchPrefix: '/versions' },
  { to: '/manage', label: t('market.nav.manage'), matchPrefix: '/manage' },
  { to: '/me', label: t('market.nav.me'), matchPrefix: '/me' },
])

const uiLocale = ref<LocalePreference>(getLocalePreference())

function onLocaleChange(ev: Event) {
  const v = (ev.target as HTMLSelectElement).value as LocalePreference
  uiLocale.value = v
  setLocalePreference(v)
}

function navActive(to: string, exact?: boolean, matchPrefix?: string) {
  if (to === '/forum') return current.path.startsWith('/forum') || current.path.startsWith('/t/')
  if (matchPrefix) return current.path.startsWith(matchPrefix)
  if (exact) return current.name === 'home' || current.path === '/'
  return current.path === to || current.path.startsWith(`${to}/`)
}
</script>

<template>
  <header class="header">
    <div class="header-inner">
      <div class="left">
        <RouterLink to="/" class="brand">
          <span class="logo" aria-hidden="true">◇</span>
          <span class="brand-text">{{ mumu.siteTagline }}</span>
        </RouterLink>
        <nav class="nav" :aria-label="t('market.nav.mainNav')">
          <RouterLink
            v-for="n in nav"
            :key="n.to"
            :to="n.to"
            class="nav-link"
            active-class=""
            exact-active-class=""
            :class="{ 'nav-link--active': navActive(n.to, n.exact, n.matchPrefix) }"
          >
            {{ n.label }}
          </RouterLink>
        </nav>
      </div>

      <div class="right">
        <label class="locale-wrap">
          <span class="sr-only">{{ t('market.nav.localeLabel') }}</span>
          <select class="locale-select" :value="uiLocale" @change="onLocaleChange">
            <option value="system">{{ t('market.nav.system') }}</option>
            <option value="zh-CN">{{ t('market.nav.zh') }}</option>
            <option value="en-US">{{ t('market.nav.en') }}</option>
          </select>
        </label>
        <RouterLink v-if="props.isAdmin" to="/admin" class="admin-link">{{ t('market.nav.admin') }}</RouterLink>
        <RouterLink v-if="props.isAuthed" to="/me" class="avatar-link" :title="t('market.nav.avatarTitle')">
          <AvatarImg v-if="props.avatarUrl" :stored-url="props.avatarUrl" img-class="avatar" />
          <span v-else class="avatar-fallback">{{ props.username?.slice(0, 1) || 'U' }}</span>
        </RouterLink>
        <RouterLink to="/submit" class="cta">{{ t('market.nav.cta') }}</RouterLink>
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
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px 16px;
}

.left {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px 18px;
  min-width: 0;
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
  flex-shrink: 0;
}

.logo {
  color: var(--accent);
  font-size: 1.2rem;
  line-height: 1;
}

.nav {
  display: flex;
  flex-wrap: wrap;
  gap: 6px 12px;
  font-size: 0.86rem;
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

.right {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
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

.locale-wrap {
  display: inline-flex;
  align-items: center;
}

.locale-select {
  font: inherit;
  font-size: 0.82rem;
  color: var(--fg-muted);
  background: var(--surface-2);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 6px 8px;
  cursor: pointer;
}

.locale-select:hover {
  border-color: var(--accent-soft);
  color: var(--fg);
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

.cta {
  padding: 9px 16px;
  font-size: 0.88rem;
  font-weight: 600;
  border: none;
  border-radius: 999px;
  background: var(--accent);
  color: var(--accent-fg);
  text-decoration: none;
  white-space: nowrap;
}

.cta:hover {
  filter: brightness(1.03);
}
</style>
