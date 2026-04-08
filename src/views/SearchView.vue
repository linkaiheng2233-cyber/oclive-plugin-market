<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useSiteData } from '../composables/useSiteData'
import {
  PACK_BRANCH_KINDS,
  PACK_BRANCH_LABELS,
  type CharacterPack,
  type PackBranch,
  type PackBranchKind,
} from '../types'

const route = useRoute()
const router = useRouter()
const { data, loading, error } = useSiteData()

function queryPart(key: string): string {
  const v = route.query[key]
  if (typeof v === 'string') return v.trim()
  if (Array.isArray(v) && typeof v[0] === 'string') return v[0].trim()
  return ''
}

const q = computed(() => queryPart('q'))

const kindFilters = reactive<Record<PackBranchKind, string>>({
  scene: '',
  persona: '',
  identity: '',
  world: '',
  schedule: '',
})

function syncKindFiltersFromRoute() {
  for (const k of PACK_BRANCH_KINDS) {
    kindFilters[k] = queryPart(k)
  }
}

watch(
  () => route.query,
  () => syncKindFiltersFromRoute(),
  { deep: true, immediate: true }
)

function applyBranchFilters() {
  const next: Record<string, string> = {}
  const gq = q.value
  if (gq) next.q = gq
  for (const k of PACK_BRANCH_KINDS) {
    const s = kindFilters[k].trim()
    if (s) next[k] = s
  }
  router.replace({ name: 'search', query: Object.keys(next).length ? next : {} })
}

function clearBranchFilters() {
  for (const k of PACK_BRANCH_KINDS) kindFilters[k] = ''
  const gq = q.value
  router.replace(gq ? { name: 'search', query: { q: gq } } : { name: 'search', query: {} })
}

const hasAnyBranchFilter = computed(() => PACK_BRANCH_KINDS.some((k) => kindFilters[k].trim() !== ''))

const hasSearchCriteria = computed(() => Boolean(q.value) || hasAnyBranchFilter.value)

function includesInsensitive(hay: string, needle: string) {
  return hay.toLowerCase().includes(needle.toLowerCase())
}

function matchGlobal(hay: string) {
  if (!q.value) return true
  return includesInsensitive(hay, q.value)
}

function branchBlob(b: PackBranch) {
  return [b.name, b.intro, b.author, b.id, b.kind, b.content].join(' ')
}

function branchPasses(b: PackBranch) {
  if (!matchGlobal(branchBlob(b))) return false
  const fq = kindFilters[b.kind].trim()
  if (!fq) return true
  return includesInsensitive(branchBlob(b), fq)
}

function packBlob(p: { name: string; intro: string; author: string; id: string; sections: Record<string, string> }) {
  return [p.name, p.intro, p.author, p.id, ...Object.values(p.sections)].join(' ')
}

function packPasses(p: CharacterPack) {
  if (!matchGlobal(packBlob(p))) return false
  for (const k of PACK_BRANCH_KINDS) {
    const fq = kindFilters[k].trim()
    if (!fq) continue
    const section = p.sections[k] ?? ''
    if (!includesInsensitive(section, fq)) return false
  }
  return true
}

const packHits = computed(() => {
  const packs = data.value?.character_packs ?? []
  return packs.filter((p) => packPasses(p))
})

function pluginModuleMatch(hay: string) {
  return matchGlobal(hay)
}

const pluginHits = computed(() => {
  if (!q.value) return []
  const list = data.value?.plugins ?? []
  return list.filter((p) => pluginModuleMatch([p.name, p.description, p.author, p.id, ...p.tags].join(' ')))
})

const moduleHits = computed(() => {
  if (!q.value) return []
  const list = data.value?.modules ?? []
  return list.filter((m) => pluginModuleMatch([m.name, m.intro, m.author, m.id, m.kind, ...m.tags].join(' ')))
})

const branchHits = computed(() => {
  const list = data.value?.pack_branches ?? []
  return list.filter((b) => branchPasses(b))
})

const branchHitsByKind = computed(() => {
  const map = {} as Record<PackBranchKind, PackBranch[]>
  for (const k of PACK_BRANCH_KINDS) map[k] = []
  for (const b of branchHits.value) {
    map[b.kind].push(b)
  }
  return map
})

const total = computed(
  () => packHits.value.length + pluginHits.value.length + moduleHits.value.length + branchHits.value.length
)

const activeBranchFilterLabels = computed(() =>
  PACK_BRANCH_KINDS.filter((k) => kindFilters[k].trim()).map((k) => `${PACK_BRANCH_LABELS[k]}：${kindFilters[k].trim()}`)
)
</script>

<template>
  <div class="page-head">
    <h1>搜索结果</h1>
    <p v-if="hasSearchCriteria" class="sub">
      <template v-if="q">全局关键词：<strong>{{ q }}</strong></template>
      <template v-if="q && activeBranchFilterLabels.length"> · </template>
      <template v-if="activeBranchFilterLabels.length">
        分支筛选：<strong>{{ activeBranchFilterLabels.join('；') }}</strong>
      </template>
    </p>
    <p v-else class="sub">输入关键词或下方可选分支条件后应用，也可从顶栏发起全局搜索。</p>
  </div>

  <section class="filters" aria-label="按角色包分支类型筛选">
    <h2 class="filters-title">分支组件（可选，留空则不限制该类）</h2>
    <p class="filters-hint">
      可同时为「场景、人设、身份、世界观、日程」分别输入关键词；仅对已填写的类型生效。完整包会按各段正文匹配；独立分支素材在对应类型下列出。
    </p>
    <div class="filter-grid">
      <label v-for="k in PACK_BRANCH_KINDS" :key="k" class="filter-field">
        <span class="filter-label">{{ PACK_BRANCH_LABELS[k] }}</span>
        <input
          v-model="kindFilters[k]"
          type="search"
          class="filter-input"
          :placeholder="`筛选${PACK_BRANCH_LABELS[k]}…`"
          autocomplete="off"
        />
      </label>
    </div>
    <div class="filter-actions">
      <button type="button" class="btn-apply" @click="applyBranchFilters">应用分支筛选</button>
      <button v-if="hasAnyBranchFilter" type="button" class="btn-clear" @click="clearBranchFilters">清除分支条件</button>
    </div>
  </section>

  <p v-if="loading" class="state">加载中…</p>
  <p v-else-if="error" class="state err">{{ error }}</p>
  <template v-else>
    <p v-if="!hasSearchCriteria" class="state muted">使用顶栏搜索和/或上方分支筛选查找内容。</p>
    <p v-else-if="total === 0" class="state muted">没有找到相关内容。</p>

    <section v-if="hasSearchCriteria && packHits.length" class="block">
      <h2>角色包（完整）</h2>
      <ul class="list">
        <li v-for="p in packHits" :key="p.id">
          <RouterLink :to="`/packs/${p.id}`" class="hit">{{ p.name }}</RouterLink>
          <span class="snippet">{{ p.intro }}</span>
        </li>
      </ul>
    </section>

    <section v-if="hasSearchCriteria && pluginHits.length" class="block">
      <h2>插件</h2>
      <ul class="list">
        <li v-for="p in pluginHits" :key="p.id">
          <a :href="p.repo_url" class="hit" target="_blank" rel="noopener">{{ p.name }}</a>
          <span class="snippet">{{ p.description }}</span>
        </li>
      </ul>
    </section>

    <section v-if="hasSearchCriteria && moduleHits.length" class="block">
      <h2>模块</h2>
      <ul class="list">
        <li v-for="m in moduleHits" :key="m.id">
          <a :href="m.link" class="hit" target="_blank" rel="noopener">{{ m.name }}</a>
          <span class="snippet">{{ m.intro }}</span>
        </li>
      </ul>
    </section>

    <section v-if="hasSearchCriteria && branchHits.length" class="block">
      <h2>角色包分支</h2>
      <template v-for="k in PACK_BRANCH_KINDS" :key="k">
        <div v-if="branchHitsByKind[k].length" class="branch-sub">
          <h3 class="branch-sub-title">{{ PACK_BRANCH_LABELS[k] }}</h3>
          <ul class="list">
            <li v-for="b in branchHitsByKind[k]" :key="b.id">
              <RouterLink :to="`/packs/part/${b.kind}`" class="hit">
                {{ b.name }}（{{ PACK_BRANCH_LABELS[b.kind] }}）
              </RouterLink>
              <span class="snippet">{{ b.intro }}</span>
            </li>
          </ul>
        </div>
      </template>
    </section>
  </template>
</template>

<style scoped>
.page-head {
  margin-bottom: 20px;
}
h1 {
  margin: 0 0 8px;
  font-size: 1.45rem;
}
.sub {
  margin: 0;
  color: var(--fg-muted);
  line-height: 1.5;
}

.filters {
  margin-bottom: 24px;
  padding: 16px;
  border-radius: 14px;
  border: 1px solid var(--border);
  background: var(--surface);
}
.filters-title {
  margin: 0 0 8px;
  font-size: 1rem;
  font-weight: 600;
  color: var(--fg-soft);
}
.filters-hint {
  margin: 0 0 14px;
  font-size: 0.86rem;
  color: var(--fg-muted);
  line-height: 1.5;
  max-width: 72ch;
}
.filter-grid {
  display: grid;
  gap: 12px;
  grid-template-columns: 1fr;
}
@media (min-width: 640px) {
  .filter-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
@media (min-width: 960px) {
  .filter-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}
.filter-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 0.88rem;
  color: var(--fg-muted);
}
.filter-label {
  font-weight: 600;
  color: var(--fg-soft);
}
.filter-input {
  padding: 9px 12px;
  font: inherit;
  font-size: 0.9rem;
  border: 1px solid var(--border);
  border-radius: 10px;
  background: var(--surface-2);
  color: var(--fg);
}
.filter-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 14px;
}
.btn-apply,
.btn-clear {
  padding: 9px 16px;
  font: inherit;
  font-size: 0.88rem;
  font-weight: 600;
  border-radius: 10px;
  cursor: pointer;
}
.btn-apply {
  border: none;
  background: var(--accent);
  color: var(--accent-fg);
}
.btn-clear {
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--fg-muted);
}
.btn-clear:hover {
  border-color: var(--accent-soft);
  color: var(--accent);
}

.block {
  margin-bottom: 28px;
}
.block h2 {
  margin: 0 0 10px;
  font-size: 1.05rem;
  color: var(--fg-soft);
  font-weight: 600;
}

.branch-sub {
  margin-bottom: 18px;
}
.branch-sub:last-child {
  margin-bottom: 0;
}
.branch-sub-title {
  margin: 0 0 8px;
  font-size: 0.95rem;
  color: var(--fg-muted);
  font-weight: 600;
}

.list {
  list-style: none;
  padding: 0;
  margin: 0;
}
.list li {
  padding: 10px 0;
  border-bottom: 1px solid var(--border);
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.hit {
  font-weight: 600;
  color: var(--accent);
  text-decoration: none;
}
.hit:hover {
  text-decoration: underline;
}
.snippet {
  font-size: 0.88rem;
  color: var(--fg-muted);
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.state.err {
  color: var(--danger);
}
.state.muted {
  color: var(--fg-soft);
}
</style>
