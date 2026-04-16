<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { marked } from 'marked'

const ALLOWED = new Set(['ui-json-guide', 'faq', 'compatibility'])

const TITLES: Record<string, string> = {
  'ui-json-guide': '角色包配置指南',
  faq: '常见问题',
  compatibility: '版本兼容性',
}

const route = useRoute()
const router = useRouter()

const slug = computed(() => {
  const s = route.params.slug
  return typeof s === 'string' ? s : Array.isArray(s) ? s[0] : ''
})

const html = ref('')
const err = ref('')
const loading = ref(true)

async function load() {
  const s = slug.value
  if (!ALLOWED.has(s)) {
    void router.replace({ name: 'docs-creator-index' })
    return
  }
  loading.value = true
  err.value = ''
  html.value = ''
  try {
    const url = `${import.meta.env.BASE_URL}docs/creator/${s}.md`
    const res = await fetch(url)
    if (!res.ok) {
      err.value = `无法加载文档（${res.status}）`
      return
    }
    const text = await res.text()
    html.value = await marked.parse(text)
  } catch (e) {
    err.value = e instanceof Error ? e.message : '加载失败'
  } finally {
    loading.value = false
  }
}

onMounted(() => void load())
watch(slug, () => void load())
</script>

<template>
  <div class="doc-page">
    <nav class="breadcrumb" aria-label="面包屑">
      <RouterLink to="/docs/creator">创作者文档</RouterLink>
      <span aria-hidden="true"> / </span>
      <span class="current">{{ TITLES[slug] ?? slug }}</span>
    </nav>

    <p v-if="loading" class="status">加载中…</p>
    <p v-else-if="err" class="status err">{{ err }}</p>
    <article v-else class="doc-body" v-html="html" />

    <p class="back">
      <RouterLink to="/docs/creator">← 返回文档首页</RouterLink>
    </p>

    <footer class="foot">
      <a
        href="https://github.com/linkaiheng2233-cyber/oclivenewnew/tree/main/creator-docs"
        target="_blank"
        rel="noopener noreferrer"
        >GitHub 完整创作者文档（插件开发、协议、API 等）</a
      >
    </footer>
  </div>
</template>

<style scoped>
.doc-page {
  max-width: 720px;
  margin: 0 auto;
}

.breadcrumb {
  font-size: 0.88rem;
  color: var(--fg-muted);
  margin-bottom: 18px;
}

.breadcrumb a {
  color: var(--accent);
  text-decoration: none;
}

.breadcrumb a:hover {
  text-decoration: underline;
}

.current {
  color: var(--fg-soft);
}

.status {
  color: var(--fg-muted);
}

.status.err {
  color: var(--danger);
}

.back {
  margin: 28px 0 0;
  font-size: 0.92rem;
}

.back a {
  color: var(--accent);
  font-weight: 600;
  text-decoration: none;
}

.back a:hover {
  text-decoration: underline;
}

.foot {
  margin-top: 32px;
  padding-top: 20px;
  border-top: 1px solid var(--border);
  font-size: 0.88rem;
}

.foot a {
  color: var(--accent);
}
</style>

<style>
/* 全局：Markdown 正文（v-html） */
.doc-body {
  font-size: 0.96rem;
  line-height: 1.65;
  color: var(--fg);
}

.doc-body h1 {
  font-size: 1.45rem;
  margin: 0 0 16px;
  letter-spacing: -0.02em;
}

.doc-body h2 {
  font-size: 1.15rem;
  margin: 28px 0 12px;
  color: var(--fg);
}

.doc-body h3 {
  font-size: 1.05rem;
  margin: 22px 0 10px;
}

.doc-body p {
  margin: 0 0 12px;
}

.doc-body ul,
.doc-body ol {
  margin: 0 0 14px;
  padding-left: 1.35em;
}

.doc-body li {
  margin-bottom: 6px;
}

.doc-body a {
  color: var(--accent);
  font-weight: 600;
}

.doc-body code {
  font-size: 0.88em;
  padding: 2px 6px;
  border-radius: 4px;
  background: var(--code-bg);
}

.doc-body pre {
  margin: 14px 0;
  padding: 14px 16px;
  border-radius: 10px;
  background: var(--code-bg);
  border: 1px solid var(--border);
  overflow-x: auto;
  font-size: 0.85rem;
}

.doc-body pre code {
  padding: 0;
  background: none;
}

.doc-body blockquote {
  margin: 14px 0;
  padding: 10px 14px;
  border-left: 3px solid var(--accent-soft);
  background: color-mix(in srgb, var(--surface) 88%, var(--accent) 12%);
  color: var(--fg-muted);
  font-size: 0.92rem;
}

.doc-body table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.88rem;
  margin: 14px 0;
}

.doc-body th,
.doc-body td {
  border: 1px solid var(--border);
  padding: 8px 10px;
  text-align: left;
}

.doc-body th {
  background: var(--surface-2);
}
</style>
