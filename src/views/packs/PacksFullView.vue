<script setup lang="ts">
import { computed, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useSiteData } from '../../composables/useSiteData'

const { data, loading, error } = useSiteData()

const packs = computed(() => data.value?.character_packs ?? [])
const filterText = ref('')

const filtered = computed(() => {
  const q = filterText.value.trim().toLowerCase()
  if (!q) return packs.value
  return packs.value.filter((p) => {
    const blob = [p.name, p.intro, p.author, p.id, ...Object.values(p.sections)].join(' ').toLowerCase()
    return blob.includes(q)
  })
})
</script>

<template>
  <section class="section">
    <h2 class="h2">完整角色包</h2>
    <p class="sub">在下方输入关键词筛选名称、介绍或各分栏文案；点卡片进入详情（场景 / 人设 / 身份 / 世界观 / 日程）。</p>

    <label class="filter">
      <span class="sr-only">筛选完整角色包</span>
      <input
        v-model="filterText"
        type="search"
        class="filter-input"
        placeholder="输入关键词筛选，例如：书店、近未来、温和…"
        autocomplete="off"
      />
    </label>

    <p v-if="loading" class="state">加载中…</p>
    <p v-else-if="error" class="state err">{{ error }}</p>
    <template v-else>
      <p v-if="!packs.length" class="state muted">暂无完整角色包条目。</p>
      <p v-else-if="!filtered.length" class="state muted">没有匹配的完整角色包，试试别的关键词。</p>
      <ul v-else class="masonry">
        <li v-for="p in filtered" :key="p.id" class="card">
          <RouterLink :to="`/packs/${p.id}`" class="card-link">
            <div class="thumb-wrap">
              <img class="thumb" :src="p.preview_image" :alt="`${p.name} 预览`" loading="lazy" />
            </div>
            <div class="card-body">
              <h3 class="card-title">{{ p.name }}</h3>
              <p class="intro">{{ p.intro }}</p>
              <span class="author">@{{ p.author }}</span>
            </div>
          </RouterLink>
        </li>
      </ul>
    </template>
  </section>
</template>

<style scoped>
.section {
  padding-bottom: 8px;
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
  max-width: 56ch;
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

.filter-input:focus {
  outline: 2px solid color-mix(in srgb, var(--accent) 35%, transparent);
  outline-offset: 1px;
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

.card-title {
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
</style>
