<script setup lang="ts">
import { computed, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useSiteData } from '../composables/useSiteData'

const props = defineProps<{ id: string }>()
const { data, loading, error } = useSiteData()

const pack = computed(() => data.value?.character_packs.find((p) => p.id === props.id))

const tabs = [
  { key: 'scene' as const, label: '场景' },
  { key: 'persona' as const, label: '人设' },
  { key: 'identity' as const, label: '自定义身份' },
  { key: 'world' as const, label: '世界观' },
  { key: 'schedule' as const, label: '日程与生活' },
]

const active = ref<(typeof tabs)[number]['key']>('scene')

const body = computed(() => {
  if (!pack.value) return ''
  return pack.value.sections[active.value] ?? ''
})
</script>

<template>
  <p v-if="loading" class="state">加载中…</p>
  <p v-else-if="error" class="state err">{{ error }}</p>
  <div v-else-if="!pack" class="missing">
    <p>未找到该角色包。</p>
    <RouterLink :to="{ name: 'packs-full' }">返回角色包列表</RouterLink>
  </div>
  <article v-else class="detail">
    <nav class="crumb">
      <RouterLink :to="{ name: 'packs-full' }">角色包</RouterLink>
      <span class="sep">/</span>
      <span>{{ pack.name }}</span>
    </nav>

    <div class="hero">
      <div class="cover">
        <img :src="pack.preview_image" :alt="`${pack.name} 封面`" />
      </div>
      <div class="side">
        <h1>{{ pack.name }}</h1>
        <p class="intro">{{ pack.intro }}</p>
        <p class="meta"><span class="label">作者</span> {{ pack.author }}</p>
        <a class="btn" :href="pack.link" target="_blank" rel="noopener">打开资源链接</a>
      </div>
    </div>

    <div class="tabs" role="tablist" aria-label="角色包分栏">
      <button
        v-for="t in tabs"
        :key="t.key"
        type="button"
        role="tab"
        class="tab"
        :aria-selected="active === t.key"
        @click="active = t.key"
      >
        {{ t.label }}
      </button>
    </div>

    <div class="panel prose" role="tabpanel">
      {{ body }}
    </div>
  </article>
</template>

<style scoped>
.state {
  color: var(--fg-muted);
}
.state.err {
  color: var(--danger);
}
.missing {
  color: var(--fg-muted);
}
.missing a {
  color: var(--accent);
}

.crumb {
  font-size: 0.88rem;
  color: var(--fg-soft);
  margin-bottom: 18px;
}
.crumb a {
  color: var(--accent);
  text-decoration: none;
}
.crumb a:hover {
  text-decoration: underline;
}
.sep {
  margin: 0 6px;
}

.detail {
  padding-bottom: 32px;
}

.hero {
  display: grid;
  gap: 20px;
  margin-bottom: 22px;
}
@media (min-width: 720px) {
  .hero {
    grid-template-columns: minmax(0, 320px) 1fr;
    align-items: start;
  }
}

.cover {
  border-radius: 14px;
  overflow: hidden;
  border: 1px solid var(--border);
  background: var(--surface-2);
  aspect-ratio: 3 / 4;
}
.cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.side h1 {
  margin: 0 0 10px;
  font-size: 1.45rem;
  letter-spacing: -0.02em;
}
.intro {
  margin: 0 0 14px;
  color: var(--fg-muted);
  line-height: 1.55;
  max-width: 56ch;
}
.meta {
  margin: 0 0 16px;
  font-size: 0.92rem;
}
.label {
  color: var(--fg-soft);
  margin-right: 6px;
}

.btn {
  display: inline-flex;
  padding: 10px 16px;
  border-radius: 10px;
  background: var(--accent);
  color: var(--accent-fg);
  font-weight: 600;
  text-decoration: none;
  font-size: 0.92rem;
}
.btn:hover {
  filter: brightness(1.03);
}

.tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 14px;
}
.tab {
  border: 1px solid var(--border);
  background: var(--surface);
  color: var(--fg-muted);
  padding: 8px 14px;
  border-radius: 999px;
  font-size: 0.88rem;
  cursor: pointer;
}
.tab[aria-selected='true'] {
  border-color: var(--accent-soft);
  background: color-mix(in srgb, var(--accent) 12%, var(--surface));
  color: var(--fg);
  font-weight: 600;
}

.panel {
  padding: 18px 18px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--fg-muted);
  line-height: 1.65;
  white-space: pre-wrap;
}
</style>
