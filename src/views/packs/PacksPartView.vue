<script setup lang="ts">
import { computed, ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { useSiteData } from '../../composables/useSiteData'
import { PACK_BRANCH_KINDS, PACK_BRANCH_LABELS, type PackBranchKind } from '../../types'

const props = defineProps<{ kind: string }>()
const router = useRouter()
const { data, loading, error } = useSiteData()

const validKind = computed(() => {
  return PACK_BRANCH_KINDS.includes(props.kind as PackBranchKind) ? (props.kind as PackBranchKind) : null
})

const title = computed(() => (validKind.value ? PACK_BRANCH_LABELS[validKind.value] : '未知类型'))

const branches = computed(() => {
  if (!validKind.value) return []
  return (data.value?.pack_branches ?? []).filter((b) => b.kind === validKind.value)
})

const filterText = ref('')

const filtered = computed(() => {
  const q = filterText.value.trim().toLowerCase()
  if (!q) return branches.value
  return branches.value.filter((b) => {
    const blob = [b.name, b.intro, b.author, b.content, b.id].join(' ').toLowerCase()
    return blob.includes(q)
  })
})

function addToCompose(id: string) {
  if (!validKind.value) return
  router.push({
    name: 'packs-compose',
    query: { [validKind.value]: id },
  })
}
</script>

<template>
  <section class="section">
    <template v-if="!validKind">
      <p class="state err">不支持的模块类型。</p>
      <RouterLink to="/packs/full" class="back">返回完整角色包</RouterLink>
    </template>
    <template v-else>
      <h2 class="h2">{{ title }}</h2>
      <p class="sub">
        浏览本类可拆分的角色包模块。用下方搜索框缩小范围；点「选入组合」会带到「模块组合」页对应槽位。
      </p>

      <label class="filter">
        <span class="sr-only">搜索本类模块</span>
        <input
          v-model="filterText"
          type="search"
          class="filter-input"
          :placeholder="`输入关键词筛选${title}模块…`"
          autocomplete="off"
        />
      </label>

      <p v-if="loading" class="state">加载中…</p>
      <p v-else-if="error" class="state err">{{ error }}</p>
      <template v-else>
        <p v-if="!branches.length" class="state muted">暂无此类模块，可在上传里发布「角色包分支」。</p>
        <p v-else-if="!filtered.length" class="state muted">没有匹配的条目。</p>
        <ul v-else class="grid">
          <li v-for="b in filtered" :key="b.id" class="tile">
            <div class="thumb-wrap">
              <img class="thumb" :src="b.preview_image" :alt="''" loading="lazy" />
            </div>
            <div class="body">
              <h3 class="name">{{ b.name }}</h3>
              <p class="intro">{{ b.intro }}</p>
              <p class="snippet">{{ b.content }}</p>
              <div class="actions">
                <button type="button" class="btn primary" @click="addToCompose(b.id)">选入组合</button>
                <a class="btn ghost" :href="b.link" target="_blank" rel="noopener">资源链接</a>
              </div>
            </div>
          </li>
        </ul>
      </template>
    </template>
  </section>
</template>

<style scoped>
.section {
  padding-bottom: 24px;
}

.h2 {
  margin: 0 0 8px;
  font-size: 1.15rem;
}

.sub {
  margin: 0 0 14px;
  color: var(--fg-muted);
  font-size: 0.9rem;
  line-height: 1.5;
  max-width: 58ch;
}

.filter {
  display: block;
  margin-bottom: 18px;
}

.filter-input {
  width: 100%;
  max-width: 420px;
  padding: 10px 14px;
  font: inherit;
  font-size: 0.95rem;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: var(--surface-2);
  color: var(--fg);
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

.grid {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  gap: 16px;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
}

.tile {
  border-radius: 14px;
  border: 1px solid var(--border);
  overflow: hidden;
  background: var(--surface);
  box-shadow: var(--shadow);
  display: flex;
  flex-direction: column;
}

.thumb-wrap {
  aspect-ratio: 16 / 10;
  background: var(--surface-2);
}

.thumb {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.body {
  padding: 12px 14px 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex: 1;
}

.name {
  margin: 0;
  font-size: 1rem;
  font-weight: 700;
}

.intro {
  margin: 0;
  font-size: 0.86rem;
  color: var(--fg-muted);
  line-height: 1.45;
}

.snippet {
  margin: 0;
  font-size: 0.82rem;
  color: var(--fg-soft);
  line-height: 1.45;
  display: -webkit-box;
  -webkit-line-clamp: 4;
  -webkit-box-orient: vertical;
  overflow: hidden;
  flex: 1;
}

.actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 4px;
}

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 8px 12px;
  font-size: 0.82rem;
  font-weight: 600;
  border-radius: 10px;
  text-decoration: none;
  cursor: pointer;
  border: 1px solid transparent;
}

.btn.primary {
  background: var(--accent);
  color: var(--accent-fg);
  border: none;
}

.btn.ghost {
  background: var(--surface-2);
  color: var(--fg-muted);
  border-color: var(--border);
}

.back {
  color: var(--accent);
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
