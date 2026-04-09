<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { excerptBody, fetchReleases, type GitHubRelease } from '../lib/githubReleases'

const owner = (import.meta.env.VITE_RELEASE_OWNER || 'linkaiheng2233-cyber').trim()

const products = [
  {
    key: 'launcher',
    title: 'oclive 启动器',
    repo: (import.meta.env.VITE_RELEASE_REPO_LAUNCHER || 'oclive-launcher').trim(),
    blurb: '一键打开编写器与聊天软件、环境检测、角色包安装',
  },
  {
    key: 'editor',
    title: '角色包编写器',
    repo: (import.meta.env.VITE_RELEASE_REPO_EDITOR || 'oclive-pack-editor').trim(),
    blurb: '写人设与导出角色包',
  },
  {
    key: 'runtime',
    title: 'oclive 运行时（聊天）',
    repo: (import.meta.env.VITE_RELEASE_REPO_RUNTIME || 'oclivenewnew').trim(),
    blurb: '主程序：选角与对话',
  },
] as const

const loading = ref(true)
const error = ref('')
const byRepo = ref<Record<string, GitHubRelease[]>>({})
const updatedAt = ref<number | null>(null)

const repoBase = computed(() => `https://github.com/${owner}`)

async function loadAll() {
  loading.value = true
  error.value = ''
  try {
    const results = await Promise.all(
      products.map((p) => fetchReleases(owner, p.repo, 20).then((list) => [p.key, list] as const))
    )
    const map: Record<string, GitHubRelease[]> = {}
    for (const [k, list] of results) map[k] = list
    byRepo.value = map
    updatedAt.value = Date.now()
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e)
    byRepo.value = {}
  } finally {
    loading.value = false
  }
}

function formatDate(iso: string | null) {
  if (!iso) return '—'
  try {
    return new Date(iso).toLocaleString('zh-CN', {
      dateStyle: 'medium',
      timeStyle: 'short',
    })
  } catch {
    return iso
  }
}

onMounted(() => {
  void loadAll()
})
</script>

<template>
  <div class="versions-page">
    <header class="head">
      <p class="eyebrow">GitHub Releases · 公开仓库</p>
      <h1>软件版本与下载</h1>
      <p class="lead">
        下列列表直接来自 GitHub 发布页，打开本网站即可查看<strong>可更新的版本</strong>与安装包链接，无需登录。
        若列表空白，可能是该仓库尚未创建 Release。
      </p>
      <p class="owner-line">
        组织/用户：<a :href="repoBase" target="_blank" rel="noopener">{{ owner }}</a>
        <button type="button" class="btn-refresh" :disabled="loading" @click="loadAll">
          {{ loading ? '刷新中…' : '重新拉取' }}
        </button>
      </p>
      <p v-if="updatedAt && !error" class="muted tiny">
        上次成功拉取：{{ new Date(updatedAt).toLocaleString('zh-CN') }}
      </p>
    </header>

    <p v-if="loading" class="state">正在从 GitHub 读取发布列表…</p>
    <p v-else-if="error" class="state err">{{ error }}</p>

    <template v-else>
      <section v-for="p in products" :key="p.key" class="product">
        <div class="product-head">
          <h2>{{ p.title }}</h2>
          <a class="repo-link" :href="`${repoBase}/${p.repo}/releases`" target="_blank" rel="noopener">
            {{ owner }}/{{ p.repo }} → Releases
          </a>
        </div>
        <p class="blurb">{{ p.blurb }}</p>

        <ul v-if="(byRepo[p.key] ?? []).length" class="release-list">
          <li v-for="rel in byRepo[p.key] ?? []" :key="rel.id" class="release-card">
            <div class="rel-top">
              <a class="tag" :href="rel.html_url" target="_blank" rel="noopener">{{ rel.tag_name }}</a>
              <span class="date">{{ formatDate(rel.published_at) }}</span>
            </div>
            <p v-if="rel.name && rel.name !== rel.tag_name" class="rel-name">{{ rel.name }}</p>
            <p v-if="excerptBody(rel.body)" class="rel-body">{{ excerptBody(rel.body) }}</p>
            <ul v-if="rel.assets?.length" class="assets">
              <li v-for="a in rel.assets" :key="a.browser_download_url">
                <a :href="a.browser_download_url" target="_blank" rel="noopener">{{ a.name }}</a>
                <span class="size">{{ (a.size / 1024 / 1024).toFixed(1) }} MB</span>
              </li>
            </ul>
            <p v-else class="no-assets muted tiny">本标签下暂无附件，请到发布页查看说明或源码。</p>
          </li>
        </ul>
        <p v-else class="empty muted">暂无 Release，请稍后再来或前往仓库查看提交记录。</p>
      </section>
    </template>
  </div>
</template>

<style scoped>
.versions-page {
  padding-bottom: 32px;
}
.head {
  margin-bottom: 28px;
}
.eyebrow {
  margin: 0 0 8px;
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--accent);
}
h1 {
  margin: 0 0 12px;
  font-size: clamp(1.35rem, 3.2vw, 1.75rem);
  letter-spacing: -0.02em;
}
.lead {
  margin: 0 0 14px;
  max-width: 58ch;
  color: var(--fg-muted);
  line-height: 1.55;
  font-size: 0.98rem;
}
.owner-line {
  margin: 0 0 6px;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  font-size: 0.9rem;
}
.owner-line a {
  color: var(--accent);
  font-weight: 600;
}
.btn-refresh {
  padding: 6px 12px;
  font-size: 0.82rem;
  border-radius: 8px;
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--fg);
  cursor: pointer;
  font: inherit;
}
.btn-refresh:hover:not(:disabled) {
  border-color: var(--accent-soft);
  color: var(--accent);
}
.btn-refresh:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.muted {
  color: var(--fg-soft);
}
.tiny {
  font-size: 0.8rem;
}
.state {
  color: var(--fg-muted);
}
.state.err {
  color: var(--danger);
}

.product {
  margin-bottom: 36px;
  padding-bottom: 28px;
  border-bottom: 1px solid var(--border);
}
.product:last-child {
  border-bottom: none;
}
.product-head {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 6px;
}
.product-head h2 {
  margin: 0;
  font-size: 1.12rem;
}
.repo-link {
  font-size: 0.85rem;
  color: var(--accent);
  text-decoration: none;
}
.repo-link:hover {
  text-decoration: underline;
}
.blurb {
  margin: 0 0 16px;
  font-size: 0.88rem;
  color: var(--fg-muted);
}

.release-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.release-card {
  padding: 14px 16px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: var(--surface);
  box-shadow: var(--shadow);
}
.rel-top {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px 14px;
}
.tag {
  font-weight: 700;
  color: var(--accent);
  text-decoration: none;
  font-size: 0.95rem;
}
.tag:hover {
  text-decoration: underline;
}
.date {
  font-size: 0.82rem;
  color: var(--fg-soft);
}
.rel-name {
  margin: 8px 0 0;
  font-size: 0.88rem;
  color: var(--fg-muted);
}
.rel-body {
  margin: 8px 0 0;
  font-size: 0.84rem;
  color: var(--fg-muted);
  line-height: 1.45;
}
.assets {
  list-style: none;
  padding: 0;
  margin: 10px 0 0;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.assets li {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  font-size: 0.82rem;
}
.assets a {
  color: var(--accent);
}
.size {
  color: var(--fg-soft);
  font-size: 0.78rem;
}
.no-assets {
  margin: 8px 0 0;
}
.empty {
  margin: 0;
  font-size: 0.88rem;
}
</style>
