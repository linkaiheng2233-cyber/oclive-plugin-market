<script setup lang="ts">
import { onMounted, ref } from 'vue'
import type { PluginListing } from './types'

const items = ref<PluginListing[]>([])
const err = ref('')

const PROTOCOL_DOC =
  'https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/plugin-and-architecture/REMOTE_PLUGIN_PROTOCOL.md'
const MINIMAL_EXAMPLE =
  'https://github.com/linkaiheng2233-cyber/oclivenewnew/tree/main/examples/remote_plugin_minimal'

onMounted(async () => {
  try {
    const r = await fetch(`${import.meta.env.BASE_URL}data/plugins.json`)
    if (!r.ok) throw new Error(`HTTP ${r.status}`)
    const j = (await r.json()) as { plugins: PluginListing[] }
    items.value = j.plugins ?? []
  } catch (e) {
    err.value = e instanceof Error ? e.message : String(e)
  }
})
</script>

<template>
  <div class="wrap">
    <header class="hero">
      <h1>oclive 插件市场</h1>
      <p class="lead">
        收录 <strong>Remote HTTP 侧车</strong>（与角色包 <code>plugin_backends</code> 中的
        <code>remote</code> 配合）。文件与源码在作者仓库，本站仅传递信息。
      </p>
      <nav class="links">
        <a :href="PROTOCOL_DOC" target="_blank" rel="noopener">协议全文</a>
        <span class="sep">·</span>
        <a :href="MINIMAL_EXAMPLE" target="_blank" rel="noopener">最小示例</a>
      </nav>
    </header>

    <p v-if="err" class="err" role="alert">加载列表失败：{{ err }}</p>

    <ul v-else class="grid">
      <li v-for="p in items" :key="p.id" class="card">
        <h2>{{ p.name }}</h2>
        <p class="desc">{{ p.description }}</p>
        <p class="meta">
          <span>作者：{{ p.author }}</span>
          <span>最低 oclive：{{ p.min_oclive_version }}</span>
        </p>
        <p class="tags">
          <span v-for="t in p.tags" :key="t" class="tag">{{ t }}</span>
        </p>
        <a class="btn" :href="p.repo_url" target="_blank" rel="noopener"> 打开仓库 </a>
      </li>
    </ul>

    <p v-if="!err && items.length === 0" class="empty">暂无条目，请编辑 <code>public/data/plugins.json</code>。</p>

    <footer class="foot">
      <small>契约与路由说明见 oclivenewnew · creator-docs/roadmap/PLUGIN_WEB_SECTION.md</small>
    </footer>
  </div>
</template>

<style>
:root {
  font-family: system-ui, sans-serif;
  color: #1a1a1a;
  background: #f6f7f9;
}
.wrap {
  max-width: 880px;
  margin: 0 auto;
  padding: 24px 16px 48px;
}
.hero {
  margin-bottom: 28px;
}
h1 {
  font-size: 1.75rem;
  margin: 0 0 8px;
}
.lead {
  margin: 0 0 12px;
  line-height: 1.55;
  color: #444;
}
.links a {
  color: #0b57d0;
}
.sep {
  margin: 0 6px;
  color: #999;
}
.err {
  color: #b00020;
}
.grid {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.card {
  background: #fff;
  border-radius: 12px;
  padding: 16px 18px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}
.card h2 {
  margin: 0 0 8px;
  font-size: 1.15rem;
}
.desc {
  margin: 0 0 10px;
  line-height: 1.5;
  color: #333;
}
.meta {
  margin: 0 0 8px;
  font-size: 0.9rem;
  color: #666;
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}
.tags {
  margin: 0 0 12px;
}
.tag {
  display: inline-block;
  font-size: 0.75rem;
  padding: 2px 8px;
  margin-right: 6px;
  border-radius: 999px;
  background: #e8eef9;
  color: #1a3a6e;
}
.btn {
  display: inline-block;
  padding: 8px 14px;
  background: #0b57d0;
  color: #fff !important;
  text-decoration: none;
  border-radius: 8px;
  font-size: 0.95rem;
}
.btn:hover {
  filter: brightness(1.05);
}
.empty {
  color: #666;
}
.foot {
  margin-top: 40px;
  color: #888;
}
code {
  font-size: 0.9em;
  background: #eee;
  padding: 1px 5px;
  border-radius: 4px;
}
</style>
