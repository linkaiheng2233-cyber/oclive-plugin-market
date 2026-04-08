<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useSiteData } from '../../composables/useSiteData'
import {
  PACK_BRANCH_KINDS,
  PACK_BRANCH_LABELS,
  type MarketComposeExportV1,
  type PackBranchKind,
} from '../../types'

const route = useRoute()
const { data, loading, error } = useSiteData()

const branches = computed(() => data.value?.pack_branches ?? [])

const selected = reactive<Record<PackBranchKind, string>>({
  scene: '',
  persona: '',
  identity: '',
  world: '',
  schedule: '',
})

const queries = reactive<Record<PackBranchKind, string>>({
  scene: '',
  persona: '',
  identity: '',
  world: '',
  schedule: '',
})

function branchList(kind: PackBranchKind) {
  return branches.value.filter((b) => b.kind === kind)
}

function filteredFor(kind: PackBranchKind) {
  const q = queries[kind].trim().toLowerCase()
  const list = branchList(kind)
  if (!q) return list
  return list.filter((b) => {
    const blob = [b.name, b.intro, b.author, b.content].join(' ').toLowerCase()
    return blob.includes(q)
  })
}

function pick(kind: PackBranchKind, id: string) {
  selected[kind] = selected[kind] === id ? '' : id
}

function branchById(kind: PackBranchKind, id: string) {
  return branchList(kind).find((b) => b.id === id) ?? null
}

const assembled = computed(() => ({
  scene: branchById('scene', selected.scene)?.content || '',
  persona: branchById('persona', selected.persona)?.content || '',
  identity: branchById('identity', selected.identity)?.content || '',
  world: branchById('world', selected.world)?.content || '',
  schedule: branchById('schedule', selected.schedule)?.content || '',
}))

function applyRouteQuery() {
  for (const k of PACK_BRANCH_KINDS) {
    const v = route.query[k]
    if (typeof v === 'string' && branchList(k as PackBranchKind).some((b) => b.id === v)) {
      selected[k as PackBranchKind] = v
    }
  }
}

watch(
  () => route.query,
  () => applyRouteQuery(),
  { deep: true }
)

watch(
  () => data.value?.pack_branches,
  () => applyRouteQuery(),
  { deep: true }
)

applyRouteQuery()

const composeHint = ref('')

const editorBaseUrl = (import.meta.env.VITE_PACK_EDITOR_URL || 'https://linkaiheng2233-cyber.github.io/oclive-pack-editor/').replace(
  /\/?$/,
  '/',
)

function buildExport(): MarketComposeExportV1 {
  return {
    version: 1,
    source: 'oclive-plugin-market',
    assembled: {
      scene: assembled.value.scene,
      persona: assembled.value.persona,
      identity: assembled.value.identity,
      world: assembled.value.world,
      schedule: assembled.value.schedule,
    },
  }
}

const exportJsonPreview = computed(() => JSON.stringify(buildExport(), null, 2))

async function copyForEditor() {
  const text = JSON.stringify(buildExport())
  try {
    await navigator.clipboard.writeText(text)
    composeHint.value = '已复制组合 JSON。打开编写器 → 开始页 → 粘贴并「应用到简单创作」。'
  } catch {
    composeHint.value = '无法写入剪贴板，请手动复制下方 JSON。'
  }
  window.setTimeout(() => {
    if (composeHint.value.startsWith('已复制') || composeHint.value.startsWith('无法写入')) {
      composeHint.value = ''
    }
  }, 8000)
}

function openEditor() {
  window.open(editorBaseUrl, '_blank', 'noopener,noreferrer')
}
</script>

<template>
  <section class="section">
    <h2 class="h2">模块组合</h2>
    <p class="sub">
      每一类下面用搜索框缩小列表，再点卡片选中/取消。选好后可复制 JSON 到
      <strong>角色包编写器</strong>（开始页粘贴应用），合并进人设长文、世界观与身份提示。
    </p>

    <p v-if="loading" class="state">加载中…</p>
    <p v-else-if="error" class="state err">{{ error }}</p>
    <template v-else>
      <div v-for="kind in PACK_BRANCH_KINDS" :key="kind" class="block">
        <h3 class="block-title">{{ PACK_BRANCH_LABELS[kind] }}</h3>
        <input
          v-model="queries[kind]"
          type="search"
          class="q"
          :placeholder="`关键词筛选「${PACK_BRANCH_LABELS[kind]}」…`"
          autocomplete="off"
        />
        <p v-if="!branchList(kind).length" class="state muted">暂无此类模块。</p>
        <p v-else-if="!filteredFor(kind).length" class="state muted">没有匹配的模块。</p>
        <ul v-else class="chips">
          <li v-for="b in filteredFor(kind)" :key="b.id">
            <button
              type="button"
              class="chip"
              :class="{ 'chip--on': selected[kind] === b.id }"
              @click="pick(kind, b.id)"
            >
              <span class="chip-name">{{ b.name }}</span>
              <span class="chip-intro">{{ b.intro }}</span>
            </button>
          </li>
        </ul>
      </div>

      <div class="preview">
        <h3 class="preview-title">组合预览</h3>
        <div class="preview-body">
          <p v-for="kind in PACK_BRANCH_KINDS" :key="kind" class="line">
            <strong>{{ PACK_BRANCH_LABELS[kind] }}：</strong>
            <span>{{ assembled[kind] || '（未选）' }}</span>
          </p>
        </div>
        <p v-if="composeHint" class="compose-hint" role="status">{{ composeHint }}</p>
        <div class="editor-actions">
          <button type="button" class="btn-copy" @click="copyForEditor">复制组合 JSON（去编写器粘贴）</button>
          <button type="button" class="btn-open" @click="openEditor">打开角色包编写器</button>
        </div>
        <details class="json-details">
          <summary>查看 / 手动复制 JSON</summary>
          <pre class="json-pre">{{ exportJsonPreview }}</pre>
        </details>
      </div>
    </template>
  </section>
</template>

<style scoped>
.section {
  padding-bottom: 32px;
}

.h2 {
  margin: 0 0 8px;
  font-size: 1.15rem;
}

.sub {
  margin: 0 0 20px;
  color: var(--fg-muted);
  font-size: 0.9rem;
  line-height: 1.55;
  max-width: 58ch;
}

.block {
  margin-bottom: 22px;
  padding-bottom: 18px;
  border-bottom: 1px solid var(--border);
}

.block:last-of-type {
  border-bottom: none;
}

.block-title {
  margin: 0 0 10px;
  font-size: 1rem;
}

.q {
  width: 100%;
  max-width: 420px;
  margin-bottom: 12px;
  padding: 9px 12px;
  font: inherit;
  font-size: 0.9rem;
  border: 1px solid var(--border);
  border-radius: 10px;
  background: var(--surface-2);
  color: var(--fg);
}

.chips {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.chip {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 4px;
  max-width: 280px;
  padding: 10px 12px;
  text-align: left;
  font: inherit;
  cursor: pointer;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: var(--surface);
  color: var(--fg);
  transition:
    border-color 0.15s ease,
    background 0.15s ease;
}

.chip:hover {
  border-color: var(--accent-soft);
}

.chip--on {
  border-color: color-mix(in srgb, var(--accent) 50%, var(--border));
  background: color-mix(in srgb, var(--accent) 10%, var(--surface));
}

.chip-name {
  font-weight: 600;
  font-size: 0.88rem;
}

.chip-intro {
  font-size: 0.78rem;
  color: var(--fg-muted);
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.preview {
  margin-top: 8px;
  padding: 16px;
  border-radius: 14px;
  border: 1px solid var(--border);
  background: var(--surface);
}

.preview-title {
  margin: 0 0 10px;
  font-size: 1rem;
}

.preview-body {
  margin-bottom: 14px;
}

.line {
  margin: 0 0 8px;
  font-size: 0.88rem;
  color: var(--fg-muted);
  line-height: 1.5;
}

.compose-hint {
  margin: 0 0 10px;
  font-size: 0.86rem;
  color: var(--accent);
  line-height: 1.45;
}

.editor-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 12px;
}

.btn-copy,
.btn-open {
  padding: 10px 16px;
  font-size: 0.88rem;
  font-weight: 600;
  border-radius: 10px;
  cursor: pointer;
  font: inherit;
}

.btn-copy {
  border: none;
  background: var(--accent);
  color: var(--accent-fg);
}

.btn-open {
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--fg-muted);
}

.btn-open:hover {
  border-color: var(--accent-soft);
  color: var(--accent);
}

.json-details {
  margin-top: 8px;
  font-size: 0.82rem;
  color: var(--fg-muted);
}

.json-pre {
  margin: 8px 0 0;
  padding: 12px;
  font-size: 0.75rem;
  line-height: 1.45;
  overflow: auto;
  max-height: 220px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--fg-soft);
}

.state {
  color: var(--fg-muted);
}
.state.err {
  color: var(--danger);
}
.state.muted {
  color: var(--fg-soft);
}
</style>
