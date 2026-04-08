<script setup lang="ts">
import { computed, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useSiteData } from '../composables/useSiteData'
import type { PackBranchKind } from '../types'

const { data, loading, error } = useSiteData()

const packs = computed(() => data.value?.character_packs ?? [])
const branches = computed(() => data.value?.pack_branches ?? [])

const selected = ref<Record<PackBranchKind, string>>({
  scene: '',
  persona: '',
  identity: '',
  world: '',
})

const branchByKind = computed(() => ({
  scene: branches.value.filter((b) => b.kind === 'scene'),
  persona: branches.value.filter((b) => b.kind === 'persona'),
  identity: branches.value.filter((b) => b.kind === 'identity'),
  world: branches.value.filter((b) => b.kind === 'world'),
}))

function getBranch(kind: PackBranchKind) {
  return branchByKind.value[kind].find((b) => b.id === selected.value[kind]) ?? null
}

const assembled = computed(() => ({
  scene: getBranch('scene')?.content || '',
  persona: getBranch('persona')?.content || '',
  identity: getBranch('identity')?.content || '',
  world: getBranch('world')?.content || '',
}))
</script>

<template>
  <div class="page-head">
    <h1>角色包</h1>
    <p class="sub">以封面图浏览，点进查看场景、人设、身份与世界观等分栏。</p>
  </div>

  <p v-if="loading" class="state">加载中…</p>
  <p v-else-if="error" class="state err">{{ error }}</p>
  <template v-else>
    <ul v-if="packs.length" class="masonry">
      <li v-for="p in packs" :key="p.id" class="card">
        <RouterLink :to="`/packs/${p.id}`" class="card-link">
          <div class="thumb-wrap">
            <img class="thumb" :src="p.preview_image" :alt="`${p.name} 预览`" loading="lazy" />
          </div>
          <div class="card-body">
            <h2 class="title">{{ p.name }}</h2>
            <p class="intro">{{ p.intro }}</p>
            <span class="author">@{{ p.author }}</span>
          </div>
        </RouterLink>
      </li>
    </ul>
    <p v-else class="state muted">暂无完整角色包条目。</p>

    <section class="composer">
      <h2>角色包分支自由组合</h2>
      <p class="sub2">用户可按需选择场景、人设、身份、世界观分支，快速组出自己的配置。</p>

      <div class="picker-grid">
        <label class="field">
          <span>场景</span>
          <select v-model="selected.scene">
            <option value="">不选择</option>
            <option v-for="b in branchByKind.scene" :key="b.id" :value="b.id">{{ b.name }}</option>
          </select>
        </label>
        <label class="field">
          <span>人设</span>
          <select v-model="selected.persona">
            <option value="">不选择</option>
            <option v-for="b in branchByKind.persona" :key="b.id" :value="b.id">{{ b.name }}</option>
          </select>
        </label>
        <label class="field">
          <span>身份</span>
          <select v-model="selected.identity">
            <option value="">不选择</option>
            <option v-for="b in branchByKind.identity" :key="b.id" :value="b.id">{{ b.name }}</option>
          </select>
        </label>
        <label class="field">
          <span>世界观</span>
          <select v-model="selected.world">
            <option value="">不选择</option>
            <option v-for="b in branchByKind.world" :key="b.id" :value="b.id">{{ b.name }}</option>
          </select>
        </label>
      </div>

      <div class="assembled">
        <h3>组合预览</h3>
        <p><strong>场景：</strong>{{ assembled.scene || '（未选择）' }}</p>
        <p><strong>人设：</strong>{{ assembled.persona || '（未选择）' }}</p>
        <p><strong>身份：</strong>{{ assembled.identity || '（未选择）' }}</p>
        <p><strong>世界观：</strong>{{ assembled.world || '（未选择）' }}</p>
      </div>
    </section>
  </template>
</template>

<style scoped>
.page-head {
  margin-bottom: 22px;
}
h1 {
  margin: 0 0 8px;
  font-size: 1.45rem;
  letter-spacing: -0.02em;
}
.sub {
  margin: 0;
  color: var(--fg-muted);
  max-width: 48ch;
  line-height: 1.5;
}

.masonry {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  gap: 18px;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
}

.card {
  border-radius: 14px;
  overflow: hidden;
  border: 1px solid var(--border);
  background: var(--surface);
  box-shadow: var(--shadow);
}

.card-link {
  display: block;
  text-decoration: none;
  color: inherit;
}

.thumb-wrap {
  aspect-ratio: 3 / 4;
  background: var(--surface-2);
  overflow: hidden;
}

.thumb {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
  transition: transform 0.35s ease;
}

.card-link:hover .thumb {
  transform: scale(1.03);
}

.card-body {
  padding: 12px 14px 14px;
}

.title {
  margin: 0 0 6px;
  font-size: 1rem;
  font-weight: 700;
}

.intro {
  margin: 0 0 8px;
  font-size: 0.88rem;
  color: var(--fg-muted);
  line-height: 1.45;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.author {
  font-size: 0.78rem;
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

.composer {
  margin-top: 26px;
  padding: 18px;
  border-radius: 14px;
  border: 1px solid var(--border);
  background: var(--surface);
}
.composer h2 {
  margin: 0 0 8px;
  font-size: 1.1rem;
}
.sub2 {
  margin: 0 0 14px;
  color: var(--fg-muted);
  font-size: 0.9rem;
}

.picker-grid {
  display: grid;
  gap: 10px;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
}
.field {
  display: grid;
  gap: 5px;
}
.field span {
  font-size: 0.8rem;
  color: var(--fg-soft);
}
.field select {
  border: 1px solid var(--border);
  background: var(--surface-2);
  border-radius: 10px;
  padding: 8px 10px;
  font: inherit;
  color: var(--fg);
}

.assembled {
  margin-top: 14px;
  border: 1px solid var(--border);
  border-radius: 10px;
  background: var(--surface-2);
  padding: 12px;
}
.assembled h3 {
  margin: 0 0 8px;
  font-size: 0.95rem;
}
.assembled p {
  margin: 0 0 6px;
  color: var(--fg-muted);
  font-size: 0.9rem;
  line-height: 1.5;
}
</style>
