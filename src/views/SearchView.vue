<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { useSiteData } from '../composables/useSiteData'

const route = useRoute()
const { data, loading, error } = useSiteData()

const q = computed(() => (typeof route.query.q === 'string' ? route.query.q.trim() : ''))

function match(hay: string) {
  if (!q.value) return false
  return hay.toLowerCase().includes(q.value.toLowerCase())
}

const packHits = computed(() => {
  const packs = data.value?.character_packs ?? []
  return packs.filter((p) =>
    match([p.name, p.intro, p.author, p.id, ...Object.values(p.sections)].join(' '))
  )
})

const pluginHits = computed(() => {
  const list = data.value?.plugins ?? []
  return list.filter((p) => match([p.name, p.description, p.author, p.id, ...p.tags].join(' ')))
})

const moduleHits = computed(() => {
  const list = data.value?.modules ?? []
  return list.filter((m) => match([m.name, m.intro, m.author, m.id, m.kind, ...m.tags].join(' ')))
})

const branchHits = computed(() => {
  const list = data.value?.pack_branches ?? []
  return list.filter((b) => match([b.name, b.intro, b.author, b.id, b.kind, b.content].join(' ')))
})

const total = computed(
  () => packHits.value.length + pluginHits.value.length + moduleHits.value.length + branchHits.value.length
)
</script>

<template>
  <div class="page-head">
    <h1>搜索结果</h1>
    <p v-if="q" class="sub">关键词：<strong>{{ q }}</strong></p>
    <p v-else class="sub">输入关键词后按搜索，或从顶栏搜索框发起。</p>
  </div>

  <p v-if="loading" class="state">加载中…</p>
  <p v-else-if="error" class="state err">{{ error }}</p>
  <template v-else>
    <p v-if="!q" class="state muted">在顶栏输入关键词并搜索，结果会按类型分组显示。</p>
    <p v-else-if="total === 0" class="state muted">没有找到相关内容。</p>

    <section v-if="q && packHits.length" class="block">
      <h2>角色包</h2>
      <ul class="list">
        <li v-for="p in packHits" :key="p.id">
          <RouterLink :to="`/packs/${p.id}`" class="hit">{{ p.name }}</RouterLink>
          <span class="snippet">{{ p.intro }}</span>
        </li>
      </ul>
    </section>

    <section v-if="q && pluginHits.length" class="block">
      <h2>插件</h2>
      <ul class="list">
        <li v-for="p in pluginHits" :key="p.id">
          <a :href="p.repo_url" class="hit" target="_blank" rel="noopener">{{ p.name }}</a>
          <span class="snippet">{{ p.description }}</span>
        </li>
      </ul>
    </section>

    <section v-if="q && moduleHits.length" class="block">
      <h2>模块</h2>
      <ul class="list">
        <li v-for="m in moduleHits" :key="m.id">
          <a :href="m.link" class="hit" target="_blank" rel="noopener">{{ m.name }}</a>
          <span class="snippet">{{ m.intro }}</span>
        </li>
      </ul>
    </section>

    <section v-if="q && branchHits.length" class="block">
      <h2>角色包分支</h2>
      <ul class="list">
        <li v-for="b in branchHits" :key="b.id">
          <RouterLink to="/packs" class="hit">{{ b.name }}（{{ b.kind }}）</RouterLink>
          <span class="snippet">{{ b.intro }}</span>
        </li>
      </ul>
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
