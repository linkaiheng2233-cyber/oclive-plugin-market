<script setup lang="ts">
import { computed, ref } from 'vue'
import { useSiteData } from '../composables/useSiteData'

const { data, loading, error } = useSiteData()

const q = ref('')
const plugins = computed(() => data.value?.plugins ?? [])

const filtered = computed(() => {
  const s = q.value.trim().toLowerCase()
  if (!s) return plugins.value
  return plugins.value.filter((p) => {
    const hay = [p.name, p.description, p.author, p.id, ...p.tags].join(' ').toLowerCase()
    return hay.includes(s)
  })
})

const PROTOCOL_DOC =
  'https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/plugin-and-architecture/REMOTE_PLUGIN_PROTOCOL.md'
</script>

<template>
  <div class="page-head">
    <h1>插件</h1>
    <p class="sub">
      与角色包中的远程侧车配合使用。下载与运行请在作者仓库完成；此处仅提供发现与兼容版本信息。
    </p>
    <p class="more">
      技术细节见
      <a :href="PROTOCOL_DOC" target="_blank" rel="noopener">Remote 协议</a>。
    </p>
  </div>

  <div class="toolbar">
    <label class="sr-only" for="plug-q">筛选插件</label>
    <input id="plug-q" v-model="q" type="search" class="search" placeholder="在当前列表中筛选…" />
  </div>

  <p v-if="loading" class="state">加载中…</p>
  <p v-else-if="error" class="state err">{{ error }}</p>
  <ul v-else-if="filtered.length" class="grid">
    <li v-for="p in filtered" :key="p.id" class="card">
      <h2>{{ p.name }}</h2>
      <p class="desc">{{ p.description }}</p>
      <dl class="meta">
        <div>
          <dt>作者</dt>
          <dd>{{ p.author }}</dd>
        </div>
        <div>
          <dt>兼容 oclive ≥</dt>
          <dd>
            <code>{{ p.min_oclive_version }}</code>
          </dd>
        </div>
      </dl>
      <p v-if="p.tags.length" class="tags">
        <span v-for="t in p.tags" :key="t" class="tag">{{ t }}</span>
      </p>
      <a class="btn" :href="p.repo_url" target="_blank" rel="noopener">前往作者仓库</a>
    </li>
  </ul>
  <p v-else class="state muted">没有匹配的插件。</p>
</template>

<style scoped>
.page-head {
  margin-bottom: 18px;
}
h1 {
  margin: 0 0 8px;
  font-size: 1.45rem;
}
.sub,
.more {
  margin: 0 0 6px;
  color: var(--fg-muted);
  max-width: 56ch;
  line-height: 1.55;
  font-size: 0.95rem;
}
.more a {
  color: var(--accent);
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
  font-size: 0.95rem;
}

.grid {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  gap: 14px;
}
@media (min-width: 720px) {
  .grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

.card {
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 16px;
  background: var(--surface);
  box-shadow: var(--shadow);
}
.card h2 {
  margin: 0 0 8px;
  font-size: 1.05rem;
}
.desc {
  margin: 0 0 10px;
  color: var(--fg-muted);
  font-size: 0.92rem;
  line-height: 1.5;
}
.meta {
  display: flex;
  gap: 20px;
  margin: 0 0 10px;
  font-size: 0.85rem;
}
.meta dt {
  margin: 0;
  font-size: 0.72rem;
  color: var(--fg-soft);
  text-transform: uppercase;
  letter-spacing: 0.04em;
}
.meta dd {
  margin: 2px 0 0;
}
.tags {
  margin: 0 0 12px;
}
.tag {
  display: inline-block;
  font-size: 0.72rem;
  padding: 3px 8px;
  margin: 0 6px 4px 0;
  border-radius: 999px;
  background: color-mix(in srgb, var(--accent) 10%, var(--surface));
}
.btn {
  display: inline-flex;
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

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
}
code {
  font-size: 0.88em;
  background: var(--code-bg);
  padding: 2px 6px;
  border-radius: 4px;
}
</style>
