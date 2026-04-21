<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { getSupabaseClient } from '../lib/supabase'
import { CONTENT_ITEM_SELECT, mapContentRow, type ContentItemRow } from '../lib/contentItems'
import { mumu } from '../content/mumuCopy'
import { CONTENT_TYPE_LABELS, type ContentItem } from '../types'
import {
  gitUrlFromContentMetadata,
  ocliveInstallHrefFromGit,
  OCLIVE_CLIENT_RELEASE_LATEST,
  pluginIndexUrlFromEnv,
} from '../lib/ocliveProtocol'

const props = defineProps<{ id: string }>()

const supabase = getSupabaseClient()
const loading = ref(true)
const err = ref('')
const item = ref<ContentItem | null>(null)

const isAnnouncement = computed(() => item.value?.type === 'announcement')
const showDownload = computed(
  () => item.value && !isAnnouncement.value && (item.value.download_url?.trim()?.length ?? 0) > 0
)

const pluginGitUrl = computed(() =>
  item.value?.type === 'plugin' ? gitUrlFromContentMetadata(item.value.metadata) : null
)
const showOcliveInstall = computed(() => (pluginGitUrl.value?.length ?? 0) > 0)
const pluginIndexUrl = pluginIndexUrlFromEnv()

function openInOcliveClient() {
  const g = pluginGitUrl.value
  if (!g) return
  window.location.href = ocliveInstallHrefFromGit(g)
}

async function load() {
  const id = props.id
  if (!supabase || !id) {
    loading.value = false
    err.value = mumu.noSupabase
    return
  }
  loading.value = true
  err.value = ''
  const { data, error } = await supabase.from('content_items').select(CONTENT_ITEM_SELECT).eq('id', id).maybeSingle()
  loading.value = false
  if (error) {
    err.value = error.message
    item.value = null
    return
  }
  item.value = data ? mapContentRow(data as ContentItemRow) : null
}

onMounted(load)
watch(
  () => props.id,
  () => load()
)

function openDownload() {
  const u = item.value?.download_url?.trim()
  if (u) window.open(u, '_blank', 'noopener,noreferrer')
}
</script>

<template>
  <div class="detail">
    <nav class="crumb">
      <RouterLink to="/browse">{{ mumu.detailCrumbBrowse }}</RouterLink>
      <span class="sep">/</span>
      <span>详情</span>
    </nav>

    <p v-if="loading" class="state">{{ mumu.detailLoading }}</p>
    <p v-else-if="err" class="state err">{{ mumu.detailLoadErr }}{{ err }}</p>
    <div v-else-if="!item" class="state">{{ mumu.detailNotFound }}</div>
    <article v-else>
      <header class="header">
        <h1>{{ item.title }}</h1>
        <p class="meta">
          <span>{{ CONTENT_TYPE_LABELS[item.type] }}</span>
          <span>作者 {{ item.author_name || '—' }}</span>
          <span>版本 {{ item.version }}</span>
        </p>
        <p v-if="item.tags?.length" class="tags">
          <span v-for="t in item.tags" :key="t" class="tag">{{ t }}</span>
        </p>
      </header>

      <section class="body prose">
        {{ item.description }}
      </section>

      <div v-if="showOcliveInstall" class="dl oclive-row">
        <button type="button" class="btn btn-oclive" @click="openInOcliveClient">
          在 Oclive 客户端安装
        </button>
        <a
          class="link-fallback"
          :href="OCLIVE_CLIENT_RELEASE_LATEST"
          target="_blank"
          rel="noopener noreferrer"
        >
          未取得 oclive:// 协议？前往 GitHub 最新版
        </a>
        <p class="hint">
          使用 <code>metadata.git</code> 作为 Git 源（非 download_url）。协议：
          <code>oclive://install?plugin=…</code>
          <template v-if="pluginIndexUrl">
            ·
            <a :href="pluginIndexUrl" target="_blank" rel="noopener noreferrer">索引 JSON</a>
          </template>
        </p>
      </div>
      <div v-if="showDownload" class="dl">
        <button type="button" class="btn" @click="openDownload">下载</button>
        <p class="hint">{{ mumu.dlHint }}</p>
      </div>
      <div
        v-if="isAnnouncement && !showDownload && !showOcliveInstall"
        class="note"
      >
        {{ mumu.detailNoDlAnnouncement }}
      </div>
    </article>
  </div>
</template>

<style scoped>
.crumb {
  font-size: 0.88rem;
  color: var(--fg-soft);
  margin-bottom: 18px;
}
.crumb a {
  color: var(--accent);
  text-decoration: none;
}
.sep {
  margin: 0 6px;
}
.state {
  color: var(--fg-muted);
}
.state.err {
  color: var(--danger);
}
.header h1 {
  margin: 0 0 10px;
  font-size: 1.55rem;
  line-height: 1.25;
}
.meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 16px;
  font-size: 0.9rem;
  color: var(--fg-muted);
  margin-bottom: 10px;
}
.tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.tag {
  font-size: 0.82rem;
  padding: 3px 8px;
  border-radius: 6px;
  background: var(--surface-2);
  color: var(--fg-muted);
}
.body {
  margin: 20px 0;
  white-space: pre-wrap;
  line-height: 1.65;
  color: var(--fg);
}
.dl {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid var(--border);
}
.btn {
  padding: 12px 28px;
  font-size: 1rem;
  font-weight: 700;
  border: none;
  border-radius: 12px;
  background: var(--accent);
  color: var(--accent-fg);
  cursor: pointer;
}
.btn:hover {
  filter: brightness(1.05);
}
.hint {
  margin: 10px 0 0;
  font-size: 0.82rem;
  color: var(--fg-soft);
  max-width: 48ch;
}
.hint a {
  color: var(--accent);
  text-decoration: none;
}
.hint a:hover {
  text-decoration: underline;
}
.note {
  margin-top: 16px;
  font-size: 0.9rem;
  color: var(--fg-muted);
}
.oclive-row {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 10px;
}
.btn-oclive {
  background: color-mix(in srgb, var(--accent) 92%, #000);
}
.link-fallback {
  font-size: 0.88rem;
  color: var(--accent);
  text-decoration: none;
}
.link-fallback:hover {
  text-decoration: underline;
}
</style>
