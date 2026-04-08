<script setup lang="ts">
import { computed, ref } from 'vue'
import { useSiteData } from '../composables/useSiteData'

const { data, loading, error } = useSiteData()
const q = ref('')

const modules = computed(() => data.value?.modules ?? [])

const filtered = computed(() => {
  const s = q.value.trim().toLowerCase()
  if (!s) return modules.value
  return modules.value.filter((m) => {
    const hay = [m.name, m.intro, m.author, m.kind, ...m.tags].join(' ').toLowerCase()
    return hay.includes(s)
  })
})
</script>

<template>
  <div class="page-head">
    <h1>可替换模块</h1>
    <p class="sub">
      记忆系统、情感引擎等可插拔能力以卡片形式展示；具体安装方式以作者链接为准。
    </p>
  </div>

  <div class="toolbar">
    <input v-model="q" type="search" class="search" placeholder="筛选模块…" />
  </div>

  <p v-if="loading" class="state">加载中…</p>
  <p v-else-if="error" class="state err">{{ error }}</p>
  <ul v-else-if="filtered.length" class="grid">
    <li v-for="m in filtered" :key="m.id" class="card">
      <div class="thumb">
        <img :src="m.preview_image" :alt="`${m.name} 预览`" loading="lazy" />
      </div>
      <div class="body">
        <h2>{{ m.name }}</h2>
        <p class="kind">{{ m.kind }}</p>
        <p class="intro">{{ m.intro }}</p>
        <p class="tags">
          <span v-for="t in m.tags" :key="t" class="tag">{{ t }}</span>
        </p>
        <p class="author">@{{ m.author }}</p>
        <a class="btn" :href="m.link" target="_blank" rel="noopener">打开说明链接</a>
      </div>
    </li>
  </ul>
  <p v-else class="state muted">没有匹配的模块。</p>
</template>

<style scoped>
.page-head {
  margin-bottom: 18px;
}
h1 {
  margin: 0 0 8px;
  font-size: 1.45rem;
}
.sub {
  margin: 0;
  color: var(--fg-muted);
  max-width: 52ch;
  line-height: 1.55;
}

.toolbar {
  margin-bottom: 18px;
}
.search {
  width: 100%;
  max-width: 360px;
  padding: 9px 12px;
  border-radius: 999px;
  border: 1px solid var(--border);
  background: var(--surface-2);
}

.grid {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  gap: 18px;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
}

.card {
  border: 1px solid var(--border);
  border-radius: 14px;
  overflow: hidden;
  background: var(--surface);
  box-shadow: var(--shadow);
  display: flex;
  flex-direction: column;
}

.thumb {
  aspect-ratio: 5 / 4;
  background: var(--surface-2);
}
.thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.body {
  padding: 14px 16px 16px;
  flex: 1;
  display: flex;
  flex-direction: column;
}
.body h2 {
  margin: 0 0 4px;
  font-size: 1.05rem;
}
.kind {
  margin: 0 0 8px;
  font-size: 0.78rem;
  color: var(--accent);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.intro {
  margin: 0 0 10px;
  font-size: 0.9rem;
  color: var(--fg-muted);
  line-height: 1.45;
  flex: 1;
}
.tags {
  margin: 0 0 8px;
}
.tag {
  font-size: 0.72rem;
  padding: 2px 8px;
  margin: 0 6px 4px 0;
  border-radius: 999px;
  background: color-mix(in srgb, var(--accent) 10%, var(--surface));
  display: inline-block;
}
.author {
  margin: 0 0 12px;
  font-size: 0.8rem;
  color: var(--fg-soft);
}
.btn {
  align-self: flex-start;
  padding: 8px 14px;
  border-radius: 10px;
  background: var(--accent);
  color: var(--accent-fg);
  font-weight: 600;
  font-size: 0.88rem;
  text-decoration: none;
}
.state.err {
  color: var(--danger);
}
.state.muted {
  color: var(--fg-soft);
}
</style>
